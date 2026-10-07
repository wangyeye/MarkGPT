#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
stage="$(mktemp -d /private/tmp/markgpt-verify.XXXXXX)"
trap 'rm -rf "$stage"' EXIT
for arch in arm64 x86_64; do
 mkdir "$stage/$arch"
 ditto -x -k "dist/MarkGPT-macOS-$arch.zip" "$stage/$arch"
 app="$stage/$arch/MarkGPT.app"
 [[ "$(lipo -archs "$app/Contents/MacOS/MarkGPT")" == "$arch" ]]
 codesign --verify --deep --strict "$app"
 [[ -f "$app/Contents/Resources/MarkGPT_MarkGPT.bundle/Web/marked.js" ]]
 if [[ "$arch" == arm64 ]]; then "$app/Contents/MacOS/MarkGPT" --self-test; fi
done
(cd dist && shasum -a 256 -c SHA256SUMS)
