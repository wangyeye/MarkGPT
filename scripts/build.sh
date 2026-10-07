#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
./scripts/make-icon.sh
source scripts/toolchain.sh
scratch="${MARKGPT_BUILD_DIR:-/private/tmp/markgpt-release}"
for arch in arm64 x86_64; do
 swift build --scratch-path "$scratch" -c release --arch "$arch" "${SWIFT_FLAGS[@]}"
 binary="$(swift build --scratch-path "$scratch" -c release --arch "$arch" "${SWIFT_FLAGS[@]}" --show-bin-path)/MarkGPT"
 ./scripts/package-app.sh "$binary" "$arch"
done
(cd dist && shasum -a 256 MarkGPT-macOS-*.zip > SHA256SUMS)
