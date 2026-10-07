#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
binary="$1"; arch="$2"
[[ "$(lipo -archs "$binary")" == "$arch" ]]
stage="$(mktemp -d /private/tmp/markgpt-package.XXXXXX)"
trap 'rm -rf "$stage"' EXIT
app="$stage/MarkGPT.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" dist
cp -X Assets/MarkGPT.icns "$app/Contents/Resources/MarkGPT.icns"
cp -X "$binary" "$app/Contents/MacOS/MarkGPT"
cp -R "$(dirname "$binary")/MarkGPT_MarkGPT.bundle" "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleIconFile</key><string>MarkGPT</string><key>CFBundleExecutable</key><string>MarkGPT</string><key>CFBundleIdentifier</key><string>local.MarkGPT.desktop</string><key>CFBundleName</key><string>MarkGPT</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.1.0</string><key>CFBundleVersion</key><string>1</string><key>LSMinimumSystemVersion</key><string>13.0</string><key>NSHighResolutionCapable</key><true/><key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict><key>CFBundleDocumentTypes</key><array><dict><key>CFBundleTypeName</key><string>Markdown</string><key>CFBundleTypeRole</key><string>Editor</string><key>CFBundleTypeExtensions</key><array><string>md</string><string>markdown</string></array></dict></array>
</dict></plist>
PLIST
plutil -lint "$app/Contents/Info.plist"
xattr -cr "$app"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
/usr/bin/ditto --norsrc --noextattr -c -k --keepParent "$app" "dist/MarkGPT-macOS-$arch.zip"
if [[ "$arch" == arm64 ]]; then /usr/bin/ditto --norsrc --noextattr "$app" dist/MarkGPT.app; fi
