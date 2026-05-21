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

To force VAAPI instead of CPU encoding, set:

```yaml
environment:
  SUNSHINE_ENCODER: "vaapi"
  SUNSHINE_ADAPTER_NAME: "/dev/dri/renderD129"
  SUNSHINE_HEVC_MODE: "2"
```

Use the render node for the GPU you want Sunshine to encode with. On a mixed NVIDIA + Intel Unraid host, the Intel iGPU is often `/dev/dri/renderD129`, but verify with `ls -l /dev/dri` and `docker exec retroarch-sunshine vainfo --display drm --device /dev/dri/renderD129`.

The override also maps `/dev/uinput` for Sunshine keyboard, mouse, and gamepad injection. If your host does not expose `/dev/uinput`, load the kernel module first:

```sh
sudo modprobe uinput
```

For NVIDIA, run the container with the NVIDIA Container Toolkit and add the appropriate GPU runtime/device settings for your host.
Set `SUNSHINE_ENCODER=nvenc` to force NVIDIA video encoding. The container also supports `XORG_DRIVER=auto`, `XORG_DRIVER=nvidia`, or `XORG_DRIVER=dummy`.
`auto` is the default and starts a headless NVIDIA-backed Xorg server when `nvidia_drv.so` is visible in the container, otherwise it falls back to the dummy Xorg driver.
Use `XORG_DRIVER=nvidia` if you want startup to fail instead of silently falling back when GPU-backed Xorg is not available.
The startup script discovers the directory containing `nvidia_drv.so` at runtime, which is helpful on hosts where the NVIDIA Container Toolkit mounts the driver under `/run/nvidia/driver`.
If the driver is under a `drivers` subdirectory such as `/usr/lib64/xorg/modules/drivers/nvidia_drv.so`, the container uses the parent Xorg module directory so NVIDIA GLX extensions can be found too.
The NVIDIA Xorg config uses `UseDisplayDevice=None` with a virtual head, so a physical monitor or dummy HDMI plug should not be required.

To confirm Xorg rendering is GPU-backed rather than Mesa software rendering, run:

```sh
docker exec retroarch-sunshine sh -c 'for root in /usr /run/nvidia/driver; do [ -e "$root" ] && find "$root" -name nvidia_drv.so -print; done'
docker exec retroarch-sunshine glxinfo -B
docker exec retroarch-sunshine grep -Ei "NVIDIA|DRISWRAST|swrast|GLX" /config/logs/xorg.log
```

If `glxinfo -B` says `llvmpipe` or the Xorg log says `DRISWRAST`, RetroArch rendering is still CPU-backed even if Sunshine encoding is using NVENC.

## Unraid template notes

When adding this container directly in Unraid's Docker UI, map both devices:

- Host path `/dev/dri` to container path `/dev/dri`
- Host path `/dev/uinput` to container path `/dev/uinput`
- Host path `/dev/input` to container path `/dev/input`

`/dev/dri` is for hardware encoding. `/dev/uinput` is what Sunshine uses to create virtual keyboard, mouse, and gamepad devices for Moonlight input.
The `/dev/input` mapping allows the container's dummy Xorg display to discover and read those virtual input devices.

In Unraid, add `/dev/input` as a **Path**, not as a Device. It must be a live bind mount so newly-created `/dev/input/event*` nodes appear inside the container.

Add these Extra Parameters so Docker's device cgroup allows dynamic input event devices:

```sh
--device-cgroup-rule='c 13:* rwm' --device-cgroup-rule='c 10:223 rwm'
```

If input still does not appear, temporarily test with `--privileged`. If privileged mode fixes it, the remaining issue is Docker device isolation rather than Sunshine or RetroArch.

If `/dev/uinput` does not exist on the Unraid host, load it before starting the container:

```sh
modprobe uinput
```

To make that persistent, add `modprobe uinput` to Unraid's boot script, such as `/boot/config/go`, before Docker containers are started.

After starting the container, verify input support with:

```sh
docker exec retroarch-sunshine test -e /dev/uinput
docker exec retroarch-sunshine test -d /dev/input
docker exec retroarch-sunshine xinput list
docker exec retroarch-sunshine udevadm info --query=property --name=/dev/input/eventX
docker logs retroarch-sunshine | grep -i input
```

If the logs say `Unable to create virtual mouse` or `Unable to create virtual keyboard`, `/dev/uinput` is still missing or inaccessible inside the container.
If `xinput list` does not show Moonlight/Sunshine virtual input devices while a client is connected, `/dev/input` is not visible to the dummy Xorg server or the container's udev service is not running.
Replace `eventX` with the event device created for a Sunshine keyboard or mouse; its udev properties should include `ID_INPUT=1` and either `ID_INPUT_KEYBOARD=1` or `ID_INPUT_MOUSE=1`.
The container includes an input hotplug watcher that retriggers udev when Sunshine passthrough devices exist in `libinput` but are missing from `xinput`.
It also includes an XTEST fallback bridge that reads Sunshine passthrough devices directly and injects events into X11 if Xorg does not attach those devices itself.
RetroArch is configured with `input_driver = "x"` so keyboard and mouse events delivered through the dummy Xorg session are used by RetroArch.
RetroArch uses `input_joypad_driver = "udev"` so Moonlight gamepads are read from Sunshine's virtual `/dev/input` devices.

The container waits for the Xorg display to become queryable before starting Sunshine. If Sunshine still logs `Unable to find display or encoder during startup`, check `docker exec retroarch-sunshine xrandr --display :0 --query` and `/config/logs/xorg.log`.

Also make sure `SUNSHINE_ENCODER` is added as a Variable, not a Label. In Unraid's generated command it should appear as `-e 'SUNSHINE_ENCODER'='nvenc'`, not `-l 'SUNSHINE_ENCODER'='nvenc'`.
For NVIDIA-backed Xorg rendering, also add `XORG_DRIVER=nvidia` as a Variable. In Unraid's generated command it should appear as `-e 'XORG_DRIVER'='nvidia'`.
If NVIDIA Xorg logs `Failed to acquire modesetting permission` or generic modesetting logs `drmSetMaster failed: Permission denied`, add `--cap-add=SYS_ADMIN` to Extra Parameters or test with `--privileged`.

If CPU usage is high while streaming, check whether Sunshine fell back to software encoding:

```sh
docker logs retroarch-sunshine | grep -i "Found H.264 encoder"
```

`libx264 [software]` means CPU encoding. For Intel/AMD hardware encoding, set `SUNSHINE_ENCODER=vaapi` and `SUNSHINE_ADAPTER_NAME` to the correct `/dev/dri/renderD*` node.
`h264_nvenc [nvenc]` means Sunshine encoding is on NVIDIA; remaining CPU load is usually RetroArch/Xorg rendering. Use `XORG_DRIVER=nvidia` and verify with `glxinfo -B`.
When `XORG_DRIVER=nvidia`, the image defaults Sunshine to `capture=nvfbc` because the headless NVIDIA NoScanout X screen has no physical RandR output for X11 capture to enumerate. Other Xorg modes default to `capture=x11` so Sunshine does not probe PipeWire/portal capture inside the container.
The capture value is `nvfbc`, not `nfbc`.

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
