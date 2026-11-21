# 0007. Wine sync modes (esync, fsync, ntsync) deferred

Accepted, November 2026.

**Context.** Faster Wine synchronisation can reduce CPU use.

**Findings (November 2026).** The WineHQ staging packages for Ubuntu 24.04 contain neither the old esync/fsync
patches nor ntsync support (they are built against kernel headers that predate ntsync). At idle, Wine's own
server process uses about 1% CPU, compared with about 14% for the game's main thread.

**Decision.** Don't add settings that do nothing. Revisit ntsync with a Wine build that supports it, a host
kernel with the ntsync driver, and measurements under load.
