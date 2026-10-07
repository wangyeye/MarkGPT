#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
source scripts/toolchain.sh
scratch="${MARKGPT_BUILD_DIR:-/private/tmp/markgpt-build}"
swift build --scratch-path "$scratch" "${SWIFT_FLAGS[@]}"
binary="$(swift build --scratch-path "$scratch" "${SWIFT_FLAGS[@]}" --show-bin-path)/MarkGPT"
"$binary" --render-test
