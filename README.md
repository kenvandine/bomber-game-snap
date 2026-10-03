# bomber-game snap

Snap packaging for [Bomberrage (Bomber)](https://github.com/JanSeliv/Bomber), an MIT-licensed
Unreal Engine 5 game. This is a self-contained snap: the cooked Linux shipping build is
bundled in the snap.

## Layout

| Path | Purpose |
| --- | --- |
| `snap/snapcraft.yaml` | core24, strict, `gnome` extension (pulls in the gpu-2404 Mesa/Vulkan stack) |
| `snap/local/launcher.sh` | Sets up the environment and execs `Bomber-Linux-Shipping` |
| `snap/gui/` | Desktop entry and icon (the icon is upstream's `Bomber.png`) |
| `tools/build-linux-shipping.sh` | Runs UAT `BuildCookRun` and writes the build to `dist/LinuxShipping/Linux` |

## Building

UE5 needs about 100 GB of engine source, which is too much to build inside the snapcraft build
environment. The game is cooked first on a machine that has a UE 5.7 source build, and snapcraft
then dumps the result into the snap.

```sh
# 1. Cook and package the Linux shipping client (needs UE 5.7 built from source)
UE_ROOT=~/UnrealEngine tools/build-linux-shipping.sh

# 2. Pack the snap
snapcraft pack

# 3. Install and connect the interfaces that aren't auto-connected
sudo snap install --dangerous bomber-game_*.snap
sudo snap connect bomber-game:joystick
```

Upstream's git repo now ships only a blockout map. The full content (the Maya map) is in the
[upstream Releases](https://github.com/JanSeliv/Bomber/releases); unpack it into the Bomber
checkout before step 1 if you want it in the snap.

The snap version comes from the Bomber commit that was built, for example `2026.06.23+git0894f21`.

## Confinement notes

- **Graphics:** the `gnome` extension on core24 supplies Mesa and the Vulkan ICDs through
  `gpu-2404`, and NVIDIA through snapd's driver export. The snap stages only the Vulkan loader
  (`libvulkan1`). It doesn't stage `mesa-vulkan-drivers` and doesn't set `VK_ICD_FILENAMES`;
  either would break that mechanism.
- **Windowing:** `SDL_VIDEODRIVER` defaults to `x11` (XWayland) because UE5's Wayland Slate
  popups are unreliable. To try native Wayland, run `SDL_VIDEODRIVER=wayland bomber-game`.
- **Saves and config:** strict confinement already sets `HOME=$SNAP_USER_DATA`, so Unreal writes
  to `~/snap/bomber-game/current/.config/Epic/Bomber`. Unreal has no `UE_SAVEDIR` variable, so the
  launcher doesn't set one.
- **Online:** upstream uses the Steam online subsystem. The Steam client can't be reached from
  inside the sandbox, so expect Unreal to fall back to the Null subsystem (LAN only). This still
  needs to be verified.
- **Audio:** the snap stages `libasound2t64`, the core24/noble name; `libasound2` is only a
  virtual package there and can't be staged.

## QA checklist

- [ ] `VK_LOADER_DEBUG=all bomber-game` picks the host Mesa RADV/ANV or NVIDIA ICD, not llvmpipe
- [ ] `snap run --shell bomber-game -c 'ls -l /dev/input'` shows readable `event*`/`js*` with `joystick` connected
- [ ] Audio starts through PipeWire-pulse with no underruns
- [ ] No AppArmor/seccomp denials: `sudo journalctl -k | grep -i 'apparmor="DENIED"'` (or `snappy-debug`)
- [ ] All writes land under `$SNAP_USER_DATA`
