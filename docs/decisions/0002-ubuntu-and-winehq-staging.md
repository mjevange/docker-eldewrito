# 0002. Ubuntu 24.04 with WineHQ staging as the base

Accepted, November 2026.

**Context.** The server is a 32-bit Windows program and needs Wine with 32-bit support.

**Decision.** Keep Ubuntu 24.04 with WineHQ's official staging packages, as upstream did.

**Alternatives.** Arch (rolling, harder to pin); Alpine (musl, no packaged 32-bit Wine); a Windows container
(needs a Windows host); a VM (more overhead for the same work).

**Consequences.** Well-supported, official Wine builds with i386 support. The image is large (Wine plus its
prefix), so size work focuses on what we can leave out.
