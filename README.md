# RetroArch Sunshine

Docker image for running RetroArch inside a lightweight virtual X11 desktop and streaming it through Sunshine to Moonlight clients.

## Quick start

```sh
docker compose up -d --build
```

Then open the Sunshine web UI at `https://localhost:47990`, finish Sunshine setup/pairing, and choose the `RetroArch` app from Moonlight.

## Volumes

- `./config:/config` stores Sunshine state, credentials, logs, and RetroArch settings.
- `./roms:/roms:ro` exposes your ROM library inside RetroArch.

The container seeds default files on first start:

- `/config/sunshine.conf`
- `/config/apps.json`
- `/config/retroarch/retroarch.cfg`

Controller autoconfig profiles can be added under `./config/retroarch/autoconfig`.

After the first run you can edit those files on the host and restart the container.

## Ports

Sunshine requires these published ports for the web UI, pairing, and streaming:

- `47984-47990/tcp`
- `48010/tcp`
- `47998-48000/udp`

## GPU notes

For VAAPI-capable Intel/AMD hardware encoding on Linux hosts, run with the GPU override:

```sh
docker compose -f compose.yaml -f compose.gpu.yaml up -d --build
```

This maps `/dev/dri` into the container. The default `compose.yaml` does not require `/dev/dri`, so it can still start on hosts without that device.

For NVIDIA, run the container with the NVIDIA Container Toolkit and add the appropriate GPU runtime/device settings for your host.

## Resolution

Set the virtual display size through environment variables:

```yaml
environment:
  SCREEN_WIDTH: "1920"
  SCREEN_HEIGHT: "1080"
  SCREEN_DEPTH: "24"
```

## Logs

```sh
docker compose logs -f
```

Sunshine and RetroArch also write app logs under `./config/logs`.
