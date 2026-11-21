#!/bin/bash
# Image tests that need no game files, so they can run in CI.
# Usage: tests/ci.sh IMAGE        (CLI=docker|podman, default: docker if installed)
#
# check() evaluates its condition later, so single quotes and "unused" variables are intended
# shellcheck disable=SC2016,SC2034
set -u

IMAGE=${1:?usage: tests/ci.sh IMAGE}
CLI=${CLI:-$(command -v docker >/dev/null && echo docker || echo podman)}
WORK=$(mktemp -d)
failed=0
n=0

ok()   { n=$((n + 1)); echo "ok $n - $1"; }
fail() { n=$((n + 1)); failed=$((failed + 1)); echo "not ok $n - $1"; [ -n "${2-}" ] && echo "#   $2"; }
check() { if eval "$2"; then ok "$1"; else fail "$1" "${3-}"; fi; }

# Files created by the container belong to other IDs: clean up from inside one
cleanup() { "$CLI" run --rm --entrypoint rm -v "$WORK":/work "$IMAGE" -rf /work/game; rm -rf "$WORK"; }
trap cleanup EXIT

# run [args...]: start the image against $WORK/game, save output to $WORK/log, return the exit code
run() { timeout 300 "$CLI" run --rm -v "$WORK/game":/game "$@" "$IMAGE" > "$WORK/log" 2>&1; }
# in_game CMD...: run a command inside the image with the game folder mounted
in_game() { "$CLI" run --rm --entrypoint sh -v "$WORK/game":/game "$IMAGE" -c "$*"; }
# fresh_game: empty game folder with a dummy eldorado.exe (the checksum check is skipped)
fresh_game() { cleanup_game; mkdir -p "$WORK/game"; touch "$WORK/game/eldorado.exe"; }
cleanup_game() { [ -d "$WORK/game" ] && "$CLI" run --rm --entrypoint rm -v "$WORK":/work "$IMAGE" -rf /work/game; }
pref() { in_game "grep -a '^$1 ' /game/data/dewrito_prefs.cfg" | tr -d '\r'; }

echo "# image: $IMAGE ($CLI)"

# --- image metadata
meta=$("$CLI" image inspect "$IMAGE")
check "healthcheck is defined" 'grep -q "/healthcheck.sh" <<<"$meta"'
check "source label points to the repository" 'grep -q "org.opencontainers.image.source" <<<"$meta"'
check "port 11778 is exposed" 'grep -q "11778/tcp" <<<"$meta"'

# --- Wine
out=$("$CLI" run --rm --entrypoint wine "$IMAGE" cmd /c echo wine-ok 2>/dev/null | tr -d '\r')
check "wine runs a Windows program" '[ "$out" = "wine-ok" ]' "got: $out"
log=$("$CLI" run --rm --entrypoint cat "$IMAGE" /wine/winetricks.log)
check "winetricks installed vcrun2012 and winhttp" 'grep -q vcrun2012 <<<"$log" && grep -q winhttp <<<"$log"'

# --- start script exit codes
mkdir -p "$WORK/game"
run; rc=$?
check "missing game files exit with 1" '[ $rc -eq 1 ]' "exit $rc"
touch "$WORK/game/eldorado.exe"; echo wrong > "$WORK/game/mtndew.dll"
run; rc=$?
check "wrong mtndew.dll checksum exits with 10" '[ $rc -eq 10 ]' "exit $rc"
run -e SKIP_CHECKSUM_CHECK=1 -e PUID=0; rc=$?
check "PUID 0 with RUN_AS_USER exits with 20" '[ $rc -eq 20 ]' "exit $rc"
run -e SKIP_CHECKSUM_CHECK=1 -e PGID=abc; rc=$?
check "non-numeric PGID exits with 30" '[ $rc -eq 30 ]' "exit $rc"
run -e SKIP_CHECKSUM_CHECK=1 -e RUN_AS_USER= -e PUID=1000; rc=$?
check "root with a PUID set exits with 40" '[ $rc -eq 40 ]' "exit $rc"

# --- first start: defaults and ownership
fresh_game
run -e SKIP_CHECKSUM_CHECK=1 -e PUID=1001 -e PGID=1000
check "defaults are copied on first start" \
    'in_game "test -f /game/data/dewrito_prefs.cfg && test -f /game/data/server/voting.json && test -f /game/data/dewrito.json"'
check "the dummy server exit code is passed through" 'grep -q "exit code 1" "$WORK/log"'
own=$(in_game "stat -c %u:%g /game/data/dewrito_prefs.cfg")
check "files are owned by PUID:PGID (1001:1000)" '[ "$own" = "1001:1000" ]' "got $own"

fresh_game
run -e SKIP_CHECKSUM_CHECK=1 -e PUID=1000 -e PGID=100
own=$(in_game "stat -c %u:%g /game/data/dewrito_prefs.cfg")
check "PUID 1000 reuses the ubuntu user, PGID 100 works" \
    '[ "$own" = "1000:100" ] && grep -q "Reusing existing user ubuntu" "$WORK/log"' "got $own"

# --- settings from environment variables
fresh_game
run -e SKIP_CHECKSUM_CHECK=1
before=$(in_game "md5sum < /game/data/dewrito_prefs.cfg")
run -e SKIP_CHECKSUM_CHECK=1
after=$(in_game "md5sum < /game/data/dewrito_prefs.cfg")
check "no variables set leaves the config untouched" '[ -n "$before" ] && [ "$before" = "$after" ]'

mkdir -p "$WORK/secrets"; printf 'rcon secret\n' > "$WORK/secrets/rcon"; chmod 644 "$WORK/secrets/rcon"
run -e SKIP_CHECKSUM_CHECK=1 -e "SERVER_NAME=A & B | C \\o/" -e SERVER_MAX_PLAYERS=12 \
    -e RCON_PASSWORD_FILE=/run/secrets/rcon -v "$WORK/secrets":/run/secrets:ro \
    -e "DEWRITO_PREFS=$(printf 'Server.Sprint = 0 \nNo.Equals.Sign\nCustom.Key=5')"
check "SERVER_NAME keeps special characters" '[ "$(pref Server.Name)" = "Server.Name \"A & B | C \\o/\"" ]' "$(pref Server.Name)"
check "SERVER_MAX_PLAYERS is applied" '[ "$(pref Server.MaxPlayers)" = "Server.MaxPlayers \"12\"" ]'
check "RCON_PASSWORD_FILE is read" '[ "$(pref Server.RconPassword)" = "Server.RconPassword \"rcon secret\"" ]'
check "passwords are not logged" '! grep -q "rcon secret" "$WORK/log"'
check "DEWRITO_PREFS replaces and trims" '[ "$(pref Server.Sprint)" = "Server.Sprint \"0\"" ]'
check "DEWRITO_PREFS appends new keys" '[ "$(pref Custom.Key)" = "Custom.Key \"5\"" ]'
check "DEWRITO_PREFS skips lines without =" 'grep -q "without .=.: No.Equals.Sign" "$WORK/log"'

run -e SKIP_CHECKSUM_CHECK=1 -e 'SERVER_MESSAGE=say "hi"'
check "values with double quotes are skipped" 'grep -q "Skipping SERVER_MESSAGE" "$WORK/log"'

in_game "sed -i 's/\$/\r/' /game/data/dewrito_prefs.cfg"
run -e SKIP_CHECKSUM_CHECK=1 -e SERVER_NAME=crlf -e DEWRITO_PREFS=New.Key=1
lines=$(in_game "wc -l < /game/data/dewrito_prefs.cfg"); crlf=$(in_game "grep -c \$(printf '\r')\\\$ /game/data/dewrito_prefs.cfg")
check "CRLF line endings are kept" '[ "${lines:-0}" -gt 0 ] && [ "$lines" = "$crlf" ]' "$crlf of $lines lines end in CRLF"

run -e SKIP_CHECKSUM_CHECK=1 -e SERVER_PASSWORD_FILE=/does/not/exist; rc=$?
check "an unreadable *_FILE exits with 50" '[ $rc -eq 50 ]' "exit $rc"

# --- healthcheck script
"$CLI" run --rm --entrypoint /healthcheck.sh "$IMAGE" >/dev/null 2>&1; rc=$?
check "healthcheck fails when nothing listens" '[ $rc -ne 0 ]'

echo "1..$n"
if [ $failed -gt 0 ]; then echo "# $failed of $n failed"; exit 1; fi
echo "# all $n passed"
