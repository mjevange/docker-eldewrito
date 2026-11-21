# 0003. Install Wine without its recommended packages

Accepted, November 2026.

**Context.** `--install-recommends` pulled in GTK, printing, video, databases and more: desktop features a
headless server never uses.

**Decision.** Install Wine with `--no-install-recommends` and add back only what the server needs: GnuTLS
(encryption, used for stats signing and HTTPS), FreeType and Fontconfig, the X11 libraries Wine's display driver
uses on Xvfb, D-Bus, and 32-bit Vulkan and GL.

**Alternatives.** Keep all recommendations (about 360 MB larger).

**Consequences.** A smaller image and less to patch. A feature that needs a removed library would fail; the real
server test (`tests/game.sh`) and a join test cover this.
