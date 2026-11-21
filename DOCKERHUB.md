# ElDewrito dedicated server

Run an **ElDewrito 0.7.1** dedicated server on Linux: the Windows server under Wine, fully headless.
Bring your own game files.

A maintained fork of [DomiStyle/docker-eldewrito](https://github.com/DomiStyle/docker-eldewrito):
a drop-in replacement with a smaller image, any `PUID`/`PGID`, a health check, optional settings
through environment variables, pinned and checksummed dependencies, tests on every change and weekly
security rebuilds.

**Full documentation, source and design notes:** <https://github.com/mjevange/docker-eldewrito>

## Quick start

```yaml
services:
  eldewrito:
    image: mjevange/eldewrito:0.7.1
    restart: unless-stopped
    cap_add: [SYS_PTRACE]   # required
    init: true
    ports:
      - "11774:11774/udp"   # game
      - "11775:11775/tcp"   # info server / browser
      - "11777:11777/tcp"   # VoIP
      - "11778:11778/tcp"   # mod downloads
    volumes:
      - /opt/eldewrito:/game   # your ElDewrito 0.7.1 files
    environment:
      SERVER_NAME: "My ElDewrito server"
```

`docker compose up -d`, then check <http://your-server:11775> and that the container shows as healthy.

## Tags

| Tag | Changes? | Use it for |
|---|---|---|
| `0.7.1` | yes | **Recommended.** Newest release for ElDewrito 0.7.1, rebuilt weekly with security updates |
| `latest` | yes | Newest release for the newest ElDewrito version |
| `v0.7.1-c2.1` | never | Exactly one release (ElDewrito `0.7.1`, container `2.1`) |
| `v0.7.1-c2.1-YYYYMMDD` | never | Exactly one weekly rebuild |
| `edge` | yes | Latest development build, for testing |

## Settings

- **Server settings** through optional variables: `SERVER_NAME`, `SERVER_MESSAGE`, `SERVER_PASSWORD`,
  `SERVER_MAX_PLAYERS`, `SERVER_ANNOUNCE`, `RCON_PASSWORD`, the port variables, and `DEWRITO_PREFS` for any other
  key. Only variables you set are applied. Passwords can come from `*_FILE` (Docker secrets).
- **Files:** `PUID` / `PGID` (default `1000`, any non-root ID works).
- **Moving from `domistyle/eldewrito`:** change only the image line.

All variables, ports, exit codes and the reasoning behind each choice are in the
[README](https://github.com/mjevange/docker-eldewrito#readme).

*ElDewrito is a fan project, not affiliated with Microsoft or Bungie. MIT licensed.*
