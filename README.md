# RetroArch Sunshine

Docker image for running RetroArch inside a lightweight virtual X11 desktop and streaming it through Sunshine to Moonlight clients.

## Quick start

For a headless Linux server with `/dev/dri` hardware encoding and `/dev/uinput` input injection:

```sh
docker compose -f compose.yaml -f compose.gpu.yaml up -d --build
```

For a portable software-only test:

```sh
docker compose up -d --build
```

Then open the Sunshine web UI at `https://localhost:47990`, finish Sunshine setup/pairing, and choose the `RetroArch` app from Moonlight.

For another device on your LAN, open `https://SERVER-IP:47990`. If Sunshine shows a CSRF protection error, set the exact browser origin in `compose.yaml` and recreate the container:

```yaml
environment:
  SUNSHINE_CSRF_ALLOWED_ORIGINS: "https://SERVER-IP:47990"
```

Multiple origins can be comma-separated, for example `https://192.168.1.50:47990,https://media-server.local:47990`.

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

For VAAPI-capable Intel/AMD hardware encoding and Sunshine virtual input on Linux hosts, use `compose.gpu.yaml`. This maps `/dev/dri` into the container. The default `compose.yaml` does not require `/dev/dri`, so it can still start on hosts without that device.

The override also maps `/dev/uinput` for Sunshine keyboard, mouse, and gamepad injection. If your host does not expose `/dev/uinput`, load the kernel module first:

```sh
sudo modprobe uinput
```

For NVIDIA, run the container with the NVIDIA Container Toolkit and add the appropriate GPU runtime/device settings for your host.

## Unraid template notes

When adding this container directly in Unraid's Docker UI, map both devices:

- Host path `/dev/dri` to container path `/dev/dri`
- Host path `/dev/uinput` to container path `/dev/uinput`

`/dev/dri` is for hardware encoding. `/dev/uinput` is what Sunshine uses to create virtual keyboard, mouse, and gamepad devices for Moonlight input.

If `/dev/uinput` does not exist on the Unraid host, load it before starting the container:

```sh
modprobe uinput
```

To make that persistent, add `modprobe uinput` to Unraid's boot script, such as `/boot/config/go`, before Docker containers are started.

After starting the container, verify input support with:

```sh
docker exec retroarch-sunshine test -e /dev/uinput
docker logs retroarch-sunshine | grep -i input
```

If the logs say `Unable to create virtual mouse` or `Unable to create virtual keyboard`, `/dev/uinput` is still missing or inaccessible inside the container.

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
