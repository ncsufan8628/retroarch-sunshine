FROM lscr.io/linuxserver/retroarch:latest

ARG SUNSHINE_VERSION
ARG SUNSHINE_DEB_URL

LABEL org.opencontainers.image.source="https://github.com/ncsufan8628/retroarch-sunshine"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget \
      ca-certificates \
      jq \
      udev \
      pulseaudio-utils && \
    wget -O /tmp/sunshine.deb "$SUNSHINE_DEB_URL" && \
    apt-get install -y /tmp/sunshine.deb || apt-get install -f -y && \
    rm -f /tmp/sunshine.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

exec sunshine "$SUNSHINE_DIR"
EOF