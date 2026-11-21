# 0004. Build Wine and the prefix in one layer

Accepted, November 2026.

**Context.** Files deleted in a later Dockerfile step still take space in the earlier layer. Upstream also
missed the winetricks cache (`/root/.cache`) when cleaning up.

**Decision.** Install, prefix setup and cleanup run in one `RUN` step with `pipefail`.

**Consequences.** About 240 MB smaller. Any change in that step rebuilds the whole Wine layer, so frequently
changing values (like the container version) are set at the end of the Dockerfile.
