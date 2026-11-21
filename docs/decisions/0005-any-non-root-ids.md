# 0005. Accept any non-root PUID and PGID

Accepted, November 2026.

**Context.** Upstream rejected IDs below 1000 and failed on `PUID=1000`, because the Ubuntu base image already
has a user with that ID. Users worked around it (for example, by raising the minimum to 1001 in a fork).

**Decision.** Accept any ID from 1 to 60000. Reuse an existing group with the requested GID, or take over an
existing user with the requested UID (the `ubuntu` user), dropping its extra groups. `PGID` becomes the server
user's primary group.

**Consequences.** Common setups like `PUID=1000`, `PGID=100` (`users`) just work. Exit codes are unchanged.
