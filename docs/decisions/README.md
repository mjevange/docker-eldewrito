# Design decisions

Short records of why the image is built the way it is. One file per decision: context, decision,
alternatives, consequences. Add a new file rather than rewriting an old one when a decision changes.

- [0001. Fork and keep the original history](0001-fork-and-keep-history.md)
- [0002. Ubuntu 24.04 with WineHQ staging as the base](0002-ubuntu-and-winehq-staging.md)
- [0003. Install Wine without its recommended packages](0003-wine-without-recommends.md)
- [0004. Build Wine and the prefix in one layer](0004-single-layer-build.md)
- [0005. Accept any non-root PUID and PGID](0005-any-non-root-ids.md)
- [0006. Health check through the info server](0006-healthcheck.md)
- [0007. Wine sync modes (esync, fsync, ntsync) deferred](0007-sync-modes-deferred.md)
- [0008. Tag scheme and automatic releases](0008-tags-and-releases.md)
- [0009. Server settings from environment variables](0009-settings-from-environment.md)
- [0010. Testing without the game files](0010-testing-without-game-files.md)
- [0011. Pinned inputs and the update flow](0011-pinned-inputs-and-updates.md)
