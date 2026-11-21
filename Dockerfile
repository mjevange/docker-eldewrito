# Pull ubuntu image
FROM ubuntu:24.04

# Set environment variables
ENV CONTAINER_VERSION=1.3 \
    ELDEWRITO_VERSION=0.7.1 \
    MTNDEW_CHECKSUM=f1d6c49381ac1ec572f0f405e4cd406b \
    DISPLAY=:1 \
    WINEPREFIX="/wine" \
    DEBIAN_FRONTEND=noninteractive \
    RUN_AS_USER=1 \
    PUID=1000 \
    PGID=1000

# Install Wine, set up the prefix and clean up in a single layer, so that
# temporary packages, apt lists and the winetricks cache never reach the image.
RUN apt-get update && \
    apt-get install -y wget ca-certificates cabextract && \
    \
    # Wine key and repository (signed-by keyring; apt-key is deprecated)
    dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -qO /etc/apt/keyrings/winehq.asc https://dl.winehq.org/wine-builds/winehq.key && \
    echo 'deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq.asc] https://dl.winehq.org/wine-builds/ubuntu/ noble main' \
        > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    \
    # Wine staging without its desktop recommendations (GTK, printing, video,
    # databases, ...), plus only the libraries a headless server uses: TLS,
    # fonts, the X11 pieces winex11 needs on Xvfb, D-Bus, 32-bit Vulkan and GL
    apt-get install -y --no-install-recommends winehq-staging && \
    apt-get install -y --no-install-recommends xvfb xauth winbind \
        libgnutls30t64 libgnutls30t64:i386 libfreetype6 libfreetype6:i386 \
        libfontconfig1 libfontconfig1:i386 libdbus-1-3 libdbus-1-3:i386 \
        libxcursor1 libxcursor1:i386 libxi6 libxi6:i386 libxrandr2 libxrandr2:i386 \
        libxrender1 libxrender1:i386 libxfixes3 libxfixes3:i386 \
        libxcomposite1 libxcomposite1:i386 libxinerama1 libxinerama1:i386 \
        libxxf86vm1 libxxf86vm1:i386 libvulkan1:i386 libgl1:i386 && \
    \
    # Configure the wine prefix
    # WINEDLLOVERRIDES is required so wine doesn't ask any questions during setup
    wget -qO /tmp/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /tmp/winetricks && \
    (Xvfb :1 -screen 0 320x240x24 &) && \
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u && \
    wineserver -w && \
    /tmp/winetricks -q vcrun2012 winhttp && \
    wineserver -w && \
    \
    # Cleanup
    apt-get remove -y wget cabextract && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /tmp/.X1-lock /root/.cache

# Add the start script
ADD start.sh .

# Add the default configuration files
ADD defaults defaults

# Make start script executable and create necessary directories
RUN chmod +x start.sh && \
    mkdir config logs

# Set start command to execute the start script
CMD ["/start.sh"]

# Set working directory into the game directory
WORKDIR /game

# Expose necessary ports
EXPOSE 11774/udp 11775/tcp 11776/tcp 11777/tcp 11778/tcp

# Set volumes
VOLUME /game

# Healthy when the server's info endpoint answers (bash /dev/tcp: no curl or
# wget needed). Set HEALTHCHECK_PORT if Server.Port is not the default 11775.
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/${HEALTHCHECK_PORT:-11775} && \
        printf "GET / HTTP/1.0\r\n\r\n" >&3 && timeout 5 head -c 15 <&3 | grep -q " 200"'
