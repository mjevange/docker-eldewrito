# 0011. Pinned inputs and the update flow

Accepted, November 2026.

**Context.** Building from `master` URLs and floating versions makes builds unrepeatable, and a new Wine release
could break the server silently.

**Decision.**
- The Ubuntu base is pinned by digest, Wine by exact version, and winetricks by release with a SHA-256 check.
  The WineHQ key is checked by SHA-256.
- A weekly workflow looks for newer versions. When it finds one, it builds and tests, then opens a pull request.
- Wine changes must pass `tests/game.sh` before merging.
- Commits carry the maintainer's identity, so bot-authored updates (Dependabot) aren't used.

**Consequences.** Every dependency change is visible in history and tested. GitHub Action versions are pinned
by commit SHA and updated by hand.
