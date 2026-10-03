#!/bin/bash
set -e

GAME_DIR="$SNAP/opt/bomber"
BIN="$GAME_DIR/Bomber/Binaries/Linux/Bomber-Linux-Shipping"

# Libraries staged into the snap (Vulkan loader, PulseAudio, ALSA). Appended
# so the gnome extension and gpu-2404 paths keep precedence.
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$SNAP/usr/lib/x86_64-linux-gnu"

# UE5's Wayland backend still misplaces Slate popup windows, so default to
# XWayland. Users can opt in with: SDL_VIDEODRIVER=wayland bomber-game
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-x11}"

# Keep receiving gamepad input when the window loses focus.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# HOME is already $SNAP_USER_DATA under strict confinement, so Unreal's
# config, logs and saves land in $SNAP_USER_DATA/.config/Epic/Bomber.
# Make sure a writable XDG config dir exists before the engine starts.
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"

exec "$BIN" "$@"
