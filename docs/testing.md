# Testing

Two scripts, both work with Docker or Podman (`CLI=podman` to choose).

## `tests/ci.sh IMAGE`: no game files needed

Runs in CI on every push and before every publish. It starts the image against a temporary folder with a dummy
`eldorado.exe` and checks:

- image metadata (health check, labels, exposed ports)
- that Wine runs a Windows program and the winetricks components are installed
- every start script exit code
- user and group setup, including `PUID=1000` and `PGID=100`
- that default files are created on first start
- the environment settings: special characters, `*_FILE` secrets (never logged), CRLF line endings kept, and the
  config untouched when nothing is set

It takes under a minute.

## `tests/game.sh IMAGE GAME_DIR`: the real server

Starts the image against **a copy** of your ElDewrito 0.7.1 game files. The test turns announcing off and
renames the server in that copy, so it never appears in the public server list, and binds ports to
`127.0.0.1` only. It passes when the info server answers and the health check reports healthy.
`MEASURE=1` also samples idle CPU and RAM for two minutes.

Run it before tagging a release and for every Wine update (the weekly update check opens a pull request
that says so).

## Before a release

1. `tests/ci.sh` and `tests/game.sh` pass locally.
2. Optional: a real join from a game client, including a mod download (port 11778).
3. Tag `v0.7.1-c<x.y>`; the release workflow builds, tests and publishes.
