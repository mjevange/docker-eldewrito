#!/bin/bash
# Runs the real server from IMAGE against a COPY of your ElDewrito 0.7.1 game files.
# Usage: tests/game.sh IMAGE GAME_DIR      (MEASURE=1 also samples idle CPU and RAM for 2 minutes)
#
# Use a copy: the test sets the server name and turns announcing off in its config,
# so the test server never shows up in the public server list. Ports bind to 127.0.0.1 only.
set -u

IMAGE=${1:?usage: tests/game.sh IMAGE GAME_DIR}
GAME=$(realpath "${2:?usage: tests/game.sh IMAGE GAME_DIR}")
CLI=${CLI:-$(command -v docker >/dev/null && echo docker || echo podman)}
NAME=eldewrito-game-test
TEST_NAME="game.sh test server"

[ -f "$GAME/eldorado.exe" ] || { echo "No eldorado.exe in $GAME"; exit 2; }

"$CLI" rm -f "$NAME" >/dev/null 2>&1
trap '"$CLI" rm -f "$NAME" >/dev/null 2>&1' EXIT

start=$(date +%s)
"$CLI" run -d --name "$NAME" --cap-add SYS_PTRACE --init \
    -e SERVER_ANNOUNCE=0 -e SERVER_NAME="$TEST_NAME" \
    -p 127.0.0.1:11774:11774/udp -p 127.0.0.1:11775:11775 \
    -p 127.0.0.1:11777:11777 -p 127.0.0.1:11778:11778 \
    -v "$GAME":/game "$IMAGE" >/dev/null || exit 1

# 1. The info server answers with our test name
answered=""
for _ in $(seq 1 90); do
    if curl -s -m 2 http://127.0.0.1:11775/ | grep -q "\"name\":\"$TEST_NAME\""; then
        answered=$(( $(date +%s) - start )); break
    fi
    [ "$("$CLI" inspect -f '{{.State.Running}}' "$NAME")" = true ] || break
    sleep 2
done
if [ -z "$answered" ]; then
    echo "FAIL: the server did not answer on port 11775"
    "$CLI" logs --tail 30 "$NAME"
    exit 1
fi
echo "ok - server answered after ${answered}s"

# 2. The healthcheck reports healthy
if [ "$CLI" = podman ]; then
    "$CLI" healthcheck run "$NAME" >/dev/null && health=healthy || health=unhealthy
else
    health=starting
    for _ in $(seq 1 30); do
        health=$("$CLI" inspect -f '{{.State.Health.Status}}' "$NAME")
        [ "$health" = starting ] || break
        sleep 5
    done
fi
if [ "$health" != healthy ]; then echo "FAIL: healthcheck: $health"; exit 1; fi
echo "ok - healthcheck: healthy"

# 3. Optional: idle CPU and RAM
if [ "${MEASURE:-0}" = 1 ]; then
    echo "# measuring idle usage for 2 minutes..."
    sleep 60
    for _ in $(seq 1 12); do
        "$CLI" stats --no-stream --format '{{.CPUPerc}} {{.MemUsage}}' "$NAME"
        sleep 5
    done | awk '{ gsub("%", "", $1); s += $1; n++; m = $2 }
        END { printf "# idle: CPU %.1f%% of one core (avg of %d samples), RAM %s\n", s / n, n, m }'
fi

echo "# all checks passed"
