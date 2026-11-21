#!/bin/bash
# Healthy when the server's HTTP info endpoint answers with 200.
# Uses bash /dev/tcp, so the image needs no curl or wget.
# Port: HEALTHCHECK_PORT if set, else Server.Port from dewrito_prefs.cfg, else 11775.
port="${HEALTHCHECK_PORT:-}"
if [ -z "$port" ]; then
    port=$(sed -n 's/^Server\.Port "\([0-9]*\)".*/\1/p' /game/data/dewrito_prefs.cfg 2>/dev/null | head -n 1)
fi
port="${port:-11775}"

exec 3<>"/dev/tcp/127.0.0.1/${port}" || exit 1
printf 'GET / HTTP/1.0\r\n\r\n' >&3
timeout 5 head -c 15 <&3 | grep -q " 200"
