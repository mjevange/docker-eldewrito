# 0008. Tag scheme and automatic releases

Accepted, November 2026.

**Context.** Upstream released by hand and never rebuilt, so images aged without security updates.

**Decision.**
- Version format `v<ElDewrito version>-c<container version>`, e.g. `v0.7.1-c2.1`. The container version never
  resets, even when ElDewrito updates.
- A git tag publishes that release (never moved afterwards) plus a dated tag, the game-version tag (`0.7.1`) and
  `latest`.
- A weekly job rebuilds the newest release with current Ubuntu updates and publishes a new dated tag, moving
  `0.7.1` and `latest`.
- Every push to master publishes `edge`.
- Images go to Docker Hub and GHCR; every publish runs the tests first.

**Consequences.** Users choose: follow `0.7.1` for automatic security updates, or pin an exact tag and update on
their own schedule.
