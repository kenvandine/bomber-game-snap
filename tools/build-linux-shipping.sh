#!/bin/bash
# Build, cook and archive the Bomber Linux shipping client with Unreal's
# Automation Tool, then place it where snap/snapcraft.yaml expects it.
#
# Usage: tools/build-linux-shipping.sh
#
# Environment:
#   UE_ROOT      Unreal Engine 5.7 source build   (default: ~/UnrealEngine)
#   BOMBER_SRC   Bomber checkout, cloned if absent (default: ~/src/Bomber)
#   BOMBER_REF   Branch, tag or commit to build    (default: current checkout)
set -euo pipefail

UE_ROOT="${UE_ROOT:-$HOME/UnrealEngine}"
BOMBER_SRC="${BOMBER_SRC:-$HOME/src/Bomber}"
BOMBER_REPO="https://github.com/JanSeliv/Bomber.git"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist/LinuxShipping"
RUN_UAT="$UE_ROOT/Engine/Build/BatchFiles/RunUAT.sh"

if [ ! -x "$RUN_UAT" ]; then
  echo "RunUAT.sh not found at $RUN_UAT; set UE_ROOT to your UE 5.7 build." >&2
  exit 1
fi

if [ ! -d "$BOMBER_SRC/.git" ]; then
  git clone --recursive "$BOMBER_REPO" "$BOMBER_SRC"
fi
if [ -n "${BOMBER_REF:-}" ]; then
  git -C "$BOMBER_SRC" fetch origin "$BOMBER_REF"
  git -C "$BOMBER_SRC" checkout --detach FETCH_HEAD
  git -C "$BOMBER_SRC" submodule update --init --recursive
fi

rm -rf "$DIST_DIR"
"$RUN_UAT" BuildCookRun \
  -project="$BOMBER_SRC/Bomber.uproject" \
  -platform=Linux \
  -clientconfig=Shipping \
  -nop4 -utf8output \
  -build -cook -stage -pak -archive \
  -archivedirectory="$DIST_DIR"

# Snap version: upstream commit date plus short hash, e.g. 2026.06.23+git0894f21
version="$(git -C "$BOMBER_SRC" log -1 --date=format:%Y.%m.%d --format='%cd+git%h')"
echo "$version" > "$DIST_DIR/Linux/VERSION"

echo "Archived Bomber $version to $DIST_DIR/Linux"
echo "Now run: snapcraft pack"
