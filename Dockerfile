FROM lizardbyte/sunshine:latest-ubuntu-24.04

LABEL org.opencontainers.image.source="https://github.com/ncsufan8628/retroarch-sunshine" \
      org.opencontainers.image.description="RetroArch running on a virtual X11 desktop streamed by Sunshine"

ARG VIRTUALGL_VERSION=3.1.4

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    VGL_DISPLAY=:0 \
    CAPTURE_DISPLAY=:1 \
    PULSE_SERVER=unix:/tmp/pulse/native \
    XDG_RUNTIME_DIR=/tmp/runtime-root \
    SCREEN_WIDTH=1920 \
    SCREEN_HEIGHT=1080 \
    SCREEN_DEPTH=24 \
    XORG_DRIVER=auto \
    TZ=Etc/UTC

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash-completion \
      ca-certificates \
      curl \
      dbus-x11 \
      evtest \
      intel-media-va-driver \
      jq \
      libegl1 \
      libgl1 \
      libglu1-mesa \
      libretro-core-info \
      libinput-tools \
      mesa-utils \
      mesa-va-drivers \
      nano \
      openbox \
      pulseaudio \
      pulseaudio-utils \
      python3 \
      python3-evdev \
      python3-xlib \
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
    curl -fsSL "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" -o /tmp/virtualgl.deb && \
    apt-get install -y --no-install-recommends /tmp/virtualgl.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/virtualgl.deb

COPY rootfs/ /

RUN chmod +x /usr/local/bin/container-start \
             /usr/local/bin/seed-config \
             /usr/local/bin/start-udev \
             /usr/local/bin/start-dbus \
             /usr/local/bin/start-pulseaudio \
             /usr/local/bin/start-xorg-dummy \
             /usr/local/bin/start-openbox \
             /usr/local/bin/start-sunshine \
             /usr/local/bin/watch-input-hotplug \
             /usr/local/bin/bridge-sunshine-input \
             /usr/local/bin/start-retroarch

VOLUME ["/config", "/roms"]

EXPOSE 47984-47990/tcp 48010/tcp 47998-48000/udp

ENTRYPOINT ["/usr/local/bin/container-start"]
