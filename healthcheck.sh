#!/bin/bash
# Healthy when the server's HTTP info endpoint answers with 200.
# Uses bash /dev/tcp, so the image needs no curl or wget.
port="${HEALTHCHECK_PORT:-11775}"

exec 3<>"/dev/tcp/127.0.0.1/${port}" || exit 1
printf 'GET / HTTP/1.0\r\n\r\n' >&3
timeout 5 head -c 15 <&3 | grep -q " 200"
