<img src="https://i.imgur.com/IkTrjna.png" width="190" height="164" align="right"/>

# ElDewrito dedicated server for Docker

Run an [ElDewrito](https://github.com/ElDewrito) 0.7.1 dedicated server on Linux. The container runs the
Windows server under Wine with a virtual display, fully headless: no GUI for setup, running or configuration.
The game files are not included; you provide your own copy.

This is a maintained fork of [DomiStyle/docker-eldewrito](https://github.com/DomiStyle/docker-eldewrito).
All credit for the original container goes to DomiStyle; its history is kept intact.

## Why this fork

Keep a small, useful image healthy for the long run:

- **Drop-in.** Same game files, ports, volumes and variables as `domistyle/eldewrito`. Switching is one line.
- **Reproducible.** The base image, Wine and winetricks are pinned and checksummed; updates arrive as reviewed changes.
- **Tested.** Every change is built and tested. Wine updates are also tested against a real server before release.
- **Kept current.** Released images are rebuilt weekly with the latest Ubuntu security updates.
- **Explained.** Each design choice is written down in [docs/decisions](docs/decisions).

## Quick start

1. Put your ElDewrito 0.7.1 game files in a folder, e.g. `/opt/eldewrito`.
2. Save this as `docker-compose.yml` (or start from [`docker-compose.yml.example`](docker-compose.yml.example)):

   ```yaml
   services:
     eldewrito:
       image: mjevange/eldewrito:0.7.1
       restart: unless-stopped
       cap_add: [SYS_PTRACE]   # required
       init: true
       ports:
         - "11774:11774/udp"
         - "11775:11775/tcp"
         - "11777:11777/tcp"
         - "11778:11778/tcp"
       volumes:
         - /opt/eldewrito:/game
       environment:
         SERVER_NAME: "My ElDewrito server"
   ```

3. Run `docker compose up -d`. The server is up when <http://your-server:11775> answers and
   `docker ps` shows the container as healthy.

On first start the container creates `data/dewrito_prefs.cfg` and voting files from
[defaults](defaults) if they don't exist yet. Edit that file, or use the variables below.

## Tags

Images are published to Docker Hub (`mjevange/eldewrito`) and GitHub (`ghcr.io/mjevange/eldewrito`).

| Tag | Changes? | Use it for |
|---|---|---|
| `0.7.1` | yes | **Recommended.** Newest release for ElDewrito 0.7.1, with weekly security rebuilds |
| `latest` | yes | Newest release for the newest ElDewrito version |
| `v0.7.1-c2.1` | never | Exactly one release. Version = ElDewrito `0.7.1`, container `2.1` |
| `v0.7.1-c2.1-20261201` | never | Exactly one weekly rebuild of that release |
| `edge` | yes | Latest commit on master. For testing only |

The image checks that your game files match its ElDewrito version, so pin a game-version tag
rather than `latest` if you don't want to be moved to a new ElDewrito release.

## Configuration

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `PUID` | `1000` | User ID the server runs as (any non-root ID) |
| `PGID` | `1000` | Group that owns the game files; also the server user's primary group (e.g. `100` for `users`) |
| `RUN_AS_USER` | `1` | Unset it to run as root (then `PUID`/`PGID` must be `0`) |
| `SKIP_CHOWN` | - | Set to `1` to skip fixing file ownership on start (faster, needs correct permissions) |
| `SKIP_CHECKSUM_CHECK` | - | Set to `1` to skip the game version check (not recommended) |
| `WAIT_ON_EXIT` | - | Set to `1` to keep the container running after the server stops (debugging) |
| `WINE_DEBUG` | - | Set to `1` for verbose Wine output |
| `HEALTHCHECK_PORT` | - | Port for the health check; normally read from `Server.Port` |

**Server settings.** These optional variables write to `data/dewrito_prefs.cfg` on every start. Only variables
you set are applied, so a hand-edited config stays untouched otherwise.

| Variable | Setting |
|---|---|
| `SERVER_NAME` | `Server.Name` |
| `SERVER_MESSAGE` | `Server.Message` |
| `SERVER_PASSWORD` | `Server.Password` |
| `SERVER_MAX_PLAYERS` | `Server.MaxPlayers` |
| `SERVER_ANNOUNCE` | `Server.ShouldAnnounce` (`0` keeps the server off the public list) |
| `HOST_NAME` | `Player.Name` |
| `RCON_PASSWORD` | `Server.RconPassword` |
| `SERVER_PORT`, `GAME_PORT`, `RCON_PORT`, `SIGNAL_SERVER_PORT`, `FILE_SERVER_PORT` | the matching `Server.*Port` / `Game.RconPort` |
| `FILE_SERVER_ENABLED` | `Server.FileServerEnabled` |
| `DEWRITO_PREFS` | Any other settings, one `Key=Value` per line (applied last) |

For passwords, prefer `SERVER_PASSWORD_FILE` / `RCON_PASSWORD_FILE` pointing at a file (e.g. a
[Docker secret](https://docs.docker.com/compose/how-tos/use-secrets/)): the value then stays out of
`docker inspect` and is never logged. Values cannot contain double quotes.

### Ports

| Port | Protocol | Purpose |
|---|---|---|
| `11774` | UDP | Game traffic |
| `11775` | TCP | Info server (server browser) |
| `11776` | TCP | RCON (keep it on `127.0.0.1` unless you need remote admin) |
| `11777` | TCP | VoIP / signal server |
| `11778` | TCP | File server (mod downloads) |

Publish ports 1:1. The server announces these numbers, so remapping them breaks joining.

### Volumes

| Path | Description |
|---|---|
| `/game` | **Required.** The ElDewrito game files. `data/` (config), `mods/` and `logs/` live inside it. |

### Health check

The container reports healthy once the info server answers, checked every 30 seconds after a 2-minute start
period. It follows `Server.Port` automatically.

### Exit codes

| Code | Meaning |
|---|---|
| `1` | `eldorado.exe` not found in `/game` |
| `10` | Game files are not ElDewrito 0.7.1 (checksum mismatch) |
| `20` / `30` | Invalid `PUID` / `PGID` |
| `40` | `PUID`/`PGID` set while running as root |
| `50` | A `*_FILE` variable points at a file that can't be read |
| other | The server's own exit code |

## Upgrading from `domistyle/eldewrito`

Change only the image line, e.g. `image: mjevange/eldewrito:0.7.1`, and run `docker compose up -d`.
Everything else stays the same. Since 2.0, `PUID=1000` and group IDs below 1000 (like `100`) work too.

## Running several servers

[`docker-compose.yml.example_multiinstance`](docker-compose.yml.example_multiinstance) runs two servers from
one copy of the game files, each with its own config and logs, using the port variables above.

## Building and testing

```sh
docker build -t eldewrito .                  # Podman: add --format docker to keep the health check
tests/ci.sh eldewrito                        # no game files needed
tests/game.sh eldewrito /path/to/game-copy   # starts the real server from a copy of your game files
```

See [docs/testing.md](docs/testing.md) and the [changelog](CHANGELOG.md).

## Credits and license

- [DomiStyle](https://github.com/DomiStyle) created this container. This fork builds on that work.
- The environment-variable settings were inspired by [thebeerkeg's fork](https://github.com/thebeerkeg/docker-eldewrito).
- ElDewrito is a fan project and is not affiliated with Microsoft or Bungie.

MIT licensed, see [LICENSE](LICENSE).
