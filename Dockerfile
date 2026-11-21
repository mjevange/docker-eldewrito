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
    # Wine staging, X virtual frame buffer, winbind, 32-bit Vulkan and GL
    apt-get install -y --install-recommends winehq-staging && \
    apt-get install -y xvfb winbind libvulkan1:i386 libgl1:i386 && \
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
EXPOSE 11774/udp 11775/tcp 11776/tcp 11777/tcp

# Set volumes
VOLUME /game
