FROM lscr.io/linuxserver/retroarch:latest

ARG SUNSHINE_VERSION

LABEL org.opencontainers.image.source="https://github.com/ncsufan8628/retroarch-sunshine"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget \
      curl \
      jq \
      udev \
      fuse \
      libfuse2t64 \
      libnotify4 \
      libxtst6 \
      libnss3 \
      libasound2t64 \
      libgbm1 \
      libxcb-xinerama0 \
      libxrandr2 \
      libxfixes3 \
      libx11-xcb1 \
      libva2 \
      libvdpau1 \
      libayatana-appindicator3-1 && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/sunshine.AppImage \
    "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine.AppImage" && \
    chmod +x /tmp/sunshine.AppImage && \
    cd /opt && \
    /tmp/sunshine.AppImage --appimage-extract && \
    mv /opt/squashfs-root /opt/sunshine && \
    ln -sf /opt/sunshine/AppRun /usr/bin/sunshine && \
    rm -f /tmp/sunshine.AppImage && \
    /usr/bin/sunshine --version || true

RUN mkdir -p /etc/s6-overlay/s6-rc.d/sunshine \
             /etc/s6-overlay/s6-rc.d/user/contents.d && \
    echo "longrun" > /etc/s6-overlay/s6-rc.d/sunshine/type && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/sunshine && \
    cat > /etc/s6-overlay/s6-rc.d/sunshine/run <<'EOF' && \
    chmod +x /etc/s6-overlay/s6-rc.d/sunshine/run
#!/usr/bin/with-contenv bash

set -e

SUNSHINE_DIR="/config/sunshine"
APPS_FILE="$SUNSHINE_DIR/apps.json"

mkdir -p "$SUNSHINE_DIR"

if [ ! -f "$APPS_FILE" ]; then
  cat > "$APPS_FILE" <<'APPS'
{
  "env": {},
  "apps": [
    {
      "name": "RetroArch",
      "cmd": "/usr/bin/retroarch",
      "detached": [],
      "image-path": ""
    }
  ]
}
APPS
fi

exec /usr/bin/sunshine "$SUNSHINE_DIR"
EOF