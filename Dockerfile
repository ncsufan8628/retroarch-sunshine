FROM lizardbyte/sunshine:latest-ubuntu-24.04

LABEL org.opencontainers.image.source="https://github.com/ncsufan8628/retroarch-sunshine" \
      org.opencontainers.image.description="RetroArch running on a virtual X11 desktop streamed by Sunshine"

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    PULSE_SERVER=unix:/tmp/pulse/native \
    XDG_RUNTIME_DIR=/tmp/runtime-root \
    SCREEN_WIDTH=1920 \
    SCREEN_HEIGHT=1080 \
    SCREEN_DEPTH=24 \
    TZ=Etc/UTC

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash-completion \
      ca-certificates \
      curl \
      dbus-x11 \
      jq \
      libegl1 \
      libgl1 \
      libglu1-mesa \
      libretro-core-info \
      mesa-utils \
      mesa-va-drivers \
      nano \
      openbox \
      pulseaudio \
      pulseaudio-utils \
      retroarch \
      retroarch-assets \
      supervisor \
      udev \
      vainfo \
      x11-xserver-utils \
      xserver-xorg-core \
      xserver-xorg-input-libinput \
      xserver-xorg-video-dummy \
      xauth \
      xdotool \
      xinput && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY rootfs/ /

RUN chmod +x /usr/local/bin/container-start \
             /usr/local/bin/seed-config \
             /usr/local/bin/start-pulseaudio \
             /usr/local/bin/start-xorg-dummy \
             /usr/local/bin/start-openbox

VOLUME ["/config", "/roms"]

EXPOSE 47984-47990/tcp 48010/tcp 47998-48000/udp

ENTRYPOINT ["/usr/local/bin/container-start"]
