#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
for tool in sips iconutil; do command -v "$tool" >/dev/null; done
source scripts/toolchain.sh
swift -module-cache-path "$CLANG_MODULE_CACHE_PATH" scripts/make-icon.swift Assets/AppIcon.png
stage="$(mktemp -d /private/tmp/markgpt-icon.XXXXXX)"
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/MarkGPT.iconset"
for size in 16 32 128 256 512; do
 sips -z "$size" "$size" Assets/AppIcon.png --out "$stage/MarkGPT.iconset/icon_${size}x${size}.png" >/dev/null
 twice=$((size*2));sips -z "$twice" "$twice" Assets/AppIcon.png --out "$stage/MarkGPT.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$stage/MarkGPT.iconset" -o Assets/MarkGPT.icns
