# Changelog

Versions are `v<ElDewrito version>-c<container version>`. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Weekly security rebuilds of a release are not listed.

## [v0.7.1-c2.1] - Unreleased

First release of the maintained fork. A drop-in replacement for `domistyle/eldewrito:v0.7.1-c1.3`.

### Added
- Optional server settings from environment variables (`SERVER_NAME`, `SERVER_PASSWORD`, `RCON_PASSWORD`,
  ports and more), `*_FILE` variants for passwords, and `DEWRITO_PREFS` for any other setting
- Health check on the info server; it follows `Server.Port`
- Tests: `tests/ci.sh` (no game files needed) and `tests/game.sh` (real server)
- Automated builds: CI on every change, releases to Docker Hub and GHCR, weekly security rebuilds and a weekly
  dependency update check
- Port 11778 (mod file server) is exposed; OCI image labels
- Documentation: rewritten README, design decision records, testing guide

### Changed
- Image about 640 MB smaller (5.43 → 4.79 GB): Wine without desktop extras, built and cleaned in one layer
- Any non-root `PUID`/`PGID` works, including `PUID=1000` and `PGID=100`
- The container exits with the server's exit code instead of always 0
- The Ubuntu base, Wine and winetricks are pinned and checksummed; the WineHQ repository uses a signed-by keyring
  instead of the deprecated `apt-key`
- Compose examples: single `/game` mount, `init`, RCON on localhost; the multi-server example uses port
  variables

### Fixed
- The winetricks download cache was left in the image
- A harmless error on start when the Xvfb lock file was missing
- A missing `data/` folder made the first start fail to create the default config

## [v0.7.1-c1.3] - 2025-02-12

Last release by [DomiStyle](https://github.com/DomiStyle/docker-eldewrito).
