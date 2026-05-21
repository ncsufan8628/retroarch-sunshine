FROM lizardbyte/sunshine:latest-ubuntu-24.04

LABEL org.opencontainers.image.source="https://github.com/ncsufan8628/retroarch-sunshine"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      retroarch \
      retroarch-assets \
      retroarch-joypad-autoconfig \
      libretro-core-info \
      mesa-utils \
      pulseaudio-utils \
      udev \
      curl \
      jq \
      ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /config/sunshine \
             /config/retroarch \
             /roms

RUN cat > /usr/local/bin/start-retroarch-sunshine <<'EOF' && \
    chmod +x /usr/local/bin/start-retroarch-sunshine
#!/usr/bin/env bash
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
      "cmd": "retroarch --menu",
      "detached": [],
      "image-path": ""
    }
  ]
}
APPS
fi

exec sunshine "$SUNSHINE_DIR"
EOF

CMD ["/usr/local/bin/start-retroarch-sunshine"]