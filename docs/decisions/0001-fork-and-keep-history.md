# 0001. Fork and keep the original history

Accepted, November 2026.

**Context.** DomiStyle's image works but was last updated in February 2025, and the maintainer has said they
want to stop. Several forks exist; none is maintained (reviewed November 2026).

**Decision.** Continue as a GitHub fork with the full history and DomiStyle's copyright kept, and publish our own
images. No pull requests are sent upstream.

**Alternatives.** A fresh repository (loses history and credit); contributing upstream (no active maintainer).

**Consequences.** Credit stays visible and `git blame` keeps working. Old upstream tags remain in the repository
as history, so automation only treats container versions from 2 up as our releases.
