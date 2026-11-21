# 0010. Testing without the game files

Accepted, November 2026.

**Context.** The game files can't be shipped or stored in CI, which is likely why upstream had no tests.

**Decision.** Two test scripts.
- `tests/ci.sh` needs no game files and runs in CI on every change. It covers image metadata, Wine, the
  winetricks components, every start-script exit code, user and group setup, default files, and environment
  settings, using a dummy `eldorado.exe`.
- `tests/game.sh` runs the real server from a local copy of the game files. It's used before releases and for
  every Wine update.

**Consequences.** Most regressions are caught automatically. Changes that only a real server can reveal (mainly
Wine) need one manual step before merging.
