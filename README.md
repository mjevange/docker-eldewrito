<img src="http://i.imgur.com/IkTrjna.png" width="190" height="164" align="right"/>

# ElDewrito dedicated server dockerized

> **Maintained fork of [DomiStyle/docker-eldewrito](https://github.com/DomiStyle/docker-eldewrito).**
> All credit for the original container goes to DomiStyle; history is kept intact. Version 2.0 is a
> drop-in replacement for `domistyle/eldewrito:v0.7.1-c1.3`: same game files, ports, volumes and
> environment variables.
>
> Changes in 2.0:
> - Smaller image: Wine installed without desktop extras, built in a single layer, caches cleaned
> - WineHQ repository set up with a signed-by keyring (`apt-key` is deprecated)
> - Any non-root `PUID`/`PGID` works, including `PGID=100` (`users`) and `PUID=1000`
> - Built-in health check on the info port
> - Port 11778 (mod file server) is exposed
>
> **Migrating from DomiStyle's image:** change only the image line, e.g.
> `image: mjevange/eldewrito:v0.7.1-c2.0`, then `docker compose up -d`.

## About

This is a Dockerfile for running the ElDewrito server under Linux. The container uses Wine to run the Windows application and xvfb to create a virtual desktop.

The container is running 100% headless - no GUI is required for installation, execution or configuration.

The game files are required in order to start this container. They are not bundled within the container and you will have to provide them.

## Usage

See [`docker-compose.yml.example`](docker-compose.yml.example) (recommended) or manually start the container with the following command:

```
docker run -d -p 11774:11774/udp -p 11775:11775/tcp -p 11776:11776/tcp -p 11777:11777/tcp -p 11778:11778/tcp -v /opt/gamepath:/game --cap-add=SYS_PTRACE mjevange/eldewrito:v0.7.1-c2.0
```

For multiple instances take a look at [`docker-compose.yml.example_multiinstance`](docker-compose.yml.example_multiinstance).

**The capability SYS_PTRACE is required due to how ElDewrito works. The server won't start without it.**

A [default configuration file](defaults/dewrito_prefs.cfg) and voting rules will be created automatically if no configuration exists in the game directory. If you do not want to use this configuration you can override this behavior by creating your own dewrito_prefs.cfg before starting the container.

### Tags

The following tags are available:

| Name       | Description |
|------------|-------------|
| `vG.G.G-cX.Y` | Pinned release: ElDewrito version `G.G.G`, container version `X.Y` (e.g. `v0.7.1-c2.0`). Recommended. |

Pin a release tag: the image checks that the game files match its ElDewrito version.

## Tutorial (for Ubuntu hosts)

1. Prepare a Ubuntu host
2. Install Docker for Ubuntu by following [this guide](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
3. Make sure Docker is working by running `docker -v`
4. Grab [`docker-compose.yml.example`](docker-compose.yml.example) from this repository (or [`docker-compose.yml.example_multiinstance`](docker-compose.yml.example_multiinstance) for multiple instances)
5. Put the file in a folder called `eldewrito` and rename it to `docker-compose.yml`
6. Switch into the folder and open the file with `nano docker-compose.yml`
7. Adjust the game path `/opt/eldewrito` if necessary
8. Put your Eldewrito game files into the folder you specified for the volume at /game
9. Run `docker compose up -d`

You're done. Your container will now be running and you can check if it is working by visting http://server_ip:11775 in your browser.

You can use `docker ps` to view running containers.

To update the container either change the image tag inside of your docker-compose.yml and run `docker compose up -d` or use `docker compose pull` followed by `docker compose up -d` if you are using the latest tag.

You can use `docker compose logs` to view the logs inside of the container.

## Configuration

### Ports
| Port       | Protocol | Description |
|------------|----------|-------------|
| `11774` | UDP | Used for the game traffic |
| `11775` | TCP | Runs the HTTP server used for communication with clients |
| `11776` | TCP | Used for controlling the server via RCon |
| `11777` | TCP | VoIP |
| `11778` | TCP | File server clients download mods from |

### Volumes

| Path       | Description | Required |
|------------|-------------|----------|
| `/game` | Has to be mounted with the ElDewrito game files in place. | Yes |
| `/game/data` | Contains the dewrito_prefs.cfg and voting.json, automatically created if left empty on start. | No |
| `/game/logs` | Contains the log files. | No |
| `/game/mods` | Contains the mod files. | No |

### Environment variables

| Variable  | Description | Default  | Required |
|-----------|-------------|----------|----------|
| `PUID` | User ID the game server runs as (any non-root ID). | 1000 | No |
| `PGID` | Group ID that owns the game files; also the server user's primary group (e.g. `100` for `users`). | 1000 | No |
| `RUN_AS_USER` | Run as `PUID`/`PGID`. Unset it to run as root (then `PUID`/`PGID` must be 0). | 1 | No |
| `SKIP_CHECKSUM_CHECK` | Set to true or 1 to disable the checksum check performed on container start. (not recommended) | - | No |
| `SKIP_CHOWN` | Skips the chowning on container startup. Speeds up container startup but requires proper directory permissions. | - | No |
| `WAIT_ON_EXIT` | Set to true or 1 to wait before the container exits. | - | No |
| `WINE_DEBUG` | Set to true or 1 to get verbose output from Wine. | - | No |
| `HEALTHCHECK_PORT` | Port the health check queries, if you changed `Server.Port`. | 11775 | No |

### Health check

The image reports healthy once the server's info endpoint (port 11775) answers, checked every 30 seconds after a
120 second start period. Override or disable it with `healthcheck:` in your compose file.

## Building

```
docker build -t eldewrito .
```

With Podman, add `--format docker`, otherwise the health check is dropped from the image.
