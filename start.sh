#!/bin/sh

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

echo "Initializing v${CONTAINER_VERSION} for ElDewrito ${ELDEWRITO_VERSION}"

# Search for eldorado.exe in game directory
if [ ! -f "eldorado.exe" ]; then
    echo "${RED}Could not find eldorado.exe. Did you mount the game directory to /game?${NC}"

    sleep 2
    exit 1
fi

# Checksum the mtndew.dll to confirm we're running the correct version
if [ -z "${SKIP_CHECKSUM_CHECK}" ]; then
    checksum=$(md5sum mtndew.dll | awk '{ print $1 }')

    if [ "$checksum" != "${MTNDEW_CHECKSUM}" ]; then
        echo "${RED}Checksum mismatch! Make sure you are using a valid copy of the game.${NC}"
        echo "${RED}This container only supports ElDewrito ${ELDEWRITO_VERSION}.${NC}"

        echo "Expected ${MTNDEW_CHECKSUM}"
        echo "Got ${checksum}"

        sleep 2
        exit 10
    fi
else
    echo "Skipping checksum check."
fi

# Create user if container should run as user
if [ -z "${RUN_AS_USER}" ]; then
    echo "Running as root"
    user=root

    if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
        echo "${RED}Tried to set PUID OR PGID without setting RUN_AS_USER.${NC}"
        echo "${RED}Please set RUN_AS_USER or remove PUID & PGID from your environment variables.${NC}"

        sleep 2
        exit 40
    fi
else
    echo "Running as eldewrito"
    user=eldewrito

    # Any non-root ID is fine (e.g. PGID 100 for the "users" group)
    case "$PUID" in ''|*[!0-9]*) PUID=0 ;; esac
    if [ "$PUID" -lt 1 ] || [ "$PUID" -gt 60000 ]; then
        echo "${RED}PUID is invalid${NC}"

        sleep 2
        exit 20
    fi

    case "$PGID" in ''|*[!0-9]*) PGID=0 ;; esac
    if [ "$PGID" -lt 1 ] || [ "$PGID" -gt 60000 ]; then
        echo "${RED}PGID is invalid${NC}"

        sleep 2
        exit 30
    fi

    if ! id -u eldewrito > /dev/null 2>&1; then
        # Reuse a group that already has this GID, otherwise create one
        if ! getent group "$PGID" > /dev/null; then
            groupadd -g "$PGID" eldewrito
        fi

        # The base image already has a user with UID 1000 (ubuntu): take it over
        # instead of failing, otherwise create the user
        existing=$(getent passwd "$PUID" | cut -d: -f1)
        if [ -n "$existing" ]; then
            echo "Reusing existing user $existing as eldewrito"
            usermod -l eldewrito -g "$PGID" -G "" -d /tmp/home -m "$existing"
        else
            echo "Creating user"
            useradd -u "$PUID" -g "$PGID" -m -d /tmp/home eldewrito
        fi
    fi
fi

# Create a server directory if it doesn't exist
if [ ! -d "data/server" ]; then
    echo "${YELLOW}Could not find an existing data/server directory. Creating one.${NC}"
    mkdir data/server
fi

# Copy dewrito_prefs.cfg if it doesn't exist
if [ ! -f "data/dewrito_prefs.cfg" ]; then
    echo "${YELLOW}Could not find an existing dewrito_prefs.cfg. Using default.${NC}"
    cp /defaults/dewrito_prefs.cfg data/
fi

# Copy voting.json if it doesn't exist
if [ ! -f "data/server/voting.json" ]; then
    echo "${YELLOW}Could not find an existing voting.json. Using default.${NC}"
    cp /defaults/voting.json data/server/
fi

# Copy dewrito.json if it doesn't exist (It is needed for the master server list)
if [ ! -f "data/dewrito.json" ]; then
    echo "${YELLOW}Could not find an existing dewrito.json. Using default.${NC}"
    cp /defaults/dewrito.json data/
fi

# Optional settings from environment variables. Only variables that are set
# change dewrito_prefs.cfg; with none set the file is left untouched.
PREFS="data/dewrito_prefs.cfg"

# set_pref KEY VALUE: replace the line 'KEY "VALUE"' or append it if missing,
# keeping the file's line endings (the game writes CRLF)
set_pref() {
    KEY="$1" VALUE="$2" awk '
        BEGIN { key = ENVIRON["KEY"]; line = key " \"" ENVIRON["VALUE"] "\"" }
        { cr = ($0 ~ /\r$/) ? "\r" : ""; if (cr != "") crlf = "\r" }
        index($0, key " \"") == 1 { print line cr; done = 1; next }
        { print }
        END { if (!done) print line crlf }
    ' "$PREFS" > "$PREFS.tmp" && cat "$PREFS.tmp" > "$PREFS" && rm -f "$PREFS.tmp"
}

# pref_from_env VAR KEY [secret]: set KEY from $VAR, or from the file named in $VAR_FILE
pref_from_env() {
    eval "value=\${$1-}"
    eval "file=\${$1_FILE-}"
    if [ -n "$file" ]; then
        if [ ! -r "$file" ]; then
            echo "${RED}$1_FILE is set but $file cannot be read${NC}"

            sleep 2
            exit 50
        fi
        value=$(cat "$file")
    fi

    [ -n "$value" ] || return 0
    case "$value" in
        *'"'*) echo "${YELLOW}Skipping $1: values cannot contain double quotes${NC}"; return 0 ;;
    esac

    set_pref "$2" "$value"
    if [ -n "$3" ]; then
        echo "Set $2 from $1 (value hidden)"
    else
        echo "Set $2 = $value"
    fi
}

pref_from_env SERVER_NAME          Server.Name
pref_from_env SERVER_MESSAGE       Server.Message
pref_from_env SERVER_PASSWORD      Server.Password secret
pref_from_env SERVER_MAX_PLAYERS   Server.MaxPlayers
pref_from_env SERVER_ANNOUNCE      Server.ShouldAnnounce
pref_from_env HOST_NAME            Player.Name
pref_from_env RCON_PASSWORD        Server.RconPassword secret
pref_from_env SERVER_PORT          Server.Port
pref_from_env GAME_PORT            Server.GamePort
pref_from_env RCON_PORT            Game.RconPort
pref_from_env SIGNAL_SERVER_PORT   Server.SignalServerPort
pref_from_env FILE_SERVER_PORT     Server.FileServerPort
pref_from_env FILE_SERVER_ENABLED  Server.FileServerEnabled

# Any other setting: DEWRITO_PREFS holds one Key=Value per line (applied last)
if [ -n "${DEWRITO_PREFS-}" ]; then
    printf '%s\n' "$DEWRITO_PREFS" | while IFS= read -r line; do
        case "$line" in ''|'#'*) continue ;; *=*) ;; *)
            echo "${YELLOW}Skipping DEWRITO_PREFS line without '=': $line${NC}"; continue ;;
        esac
        key=$(printf '%s' "${line%%=*}" | tr -d ' \t')
        value=$(printf '%s' "${line#*=}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$key" in
            ''|*[!A-Za-z0-9._]*)
                echo "${YELLOW}Skipping DEWRITO_PREFS line: $line${NC}"; continue ;;
        esac
        case "$value" in
            *'"'*) echo "${YELLOW}Skipping $key: values cannot contain double quotes${NC}"; continue ;;
        esac
        set_pref "$key" "$value"
        echo "Set $key (DEWRITO_PREFS)"
    done
fi

if [ -z "${SKIP_CHOWN}" ]; then
    echo "Taking ownership of folders"
    chown -R "$PUID:$PGID" /game /wine

    echo "Changing folder permissions"
    find /game -type d -exec chmod 775 {} \;

    echo "Changing file permissions"
    find /game -type f -exec chmod 664 {} \;
fi

# Xvfb needs cleaning because it doesn't exit cleanly
echo "Cleaning up"
rm -f /tmp/.X1-lock

echo "Starting virtual frame buffer"
Xvfb :1 -screen 0 320x240x24 &

echo "${GREEN}Starting dedicated server${NC}"

# DLL overrides for Wine are required to prevent issues with master server announcement
# native is needed to fix master server announcement
# builtin is needed to fix mod downloads
export WINEDLLOVERRIDES="winhttp,rasapi32=b,n"

if [ ! -z "${WINE_DEBUG}" ]; then
    echo "Setting wine to verbose output"
    export WINEDEBUG=warn+all
fi

su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized" $user

if [ -z "${WAIT_ON_EXIT}" ]; then
    echo "${RED}Server terminated, exiting${NC}"
else
    echo "${RED}Server terminated, waiting${NC}"
    sleep infinity
fi
