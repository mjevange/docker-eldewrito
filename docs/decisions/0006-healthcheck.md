# 0006. Health check through the info server

Accepted, November 2026.

**Context.** Without a health check, Docker can't tell a running container from a working server. The image
has no curl or wget.

**Decision.** `healthcheck.sh` sends an HTTP request to the info server with bash's `/dev/tcp` and expects a
200. It reads the port from `Server.Port` (override with `HEALTHCHECK_PORT`), with a 2-minute start period.

**Consequences.** Monitoring sees real server health. Podman drops `HEALTHCHECK` unless the image is built with
`--format docker`.
