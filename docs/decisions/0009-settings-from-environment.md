# 0009. Server settings from environment variables

Accepted, November 2026.

**Context.** Editing `dewrito_prefs.cfg` by hand is awkward in compose setups, and a second server on one game
install needed a manually edited config. The idea comes from thebeerkeg's fork.

**Decision.** Optional variables (name, message, passwords, ports, and a few others) and `DEWRITO_PREFS` for any
other key update the config on every start.
- Only variables that are set are applied; with none set, the file is not touched.
- Passwords can come from `*_FILE` and are never logged.
- Values with double quotes are rejected, because the config format can't hold them.
- The game's CRLF line endings are kept.

**Consequences.** An environment variable wins over a hand edit of the same key on every start. That's
intended, and documented.
