#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/PrivateVPNAdmin.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$ROOT_DIR/dist/PrivateVPNAdmin.iconset"
ICNS_PATH="$RESOURCES_DIR/AppIcon.icns"

mkdir -p "$ROOT_DIR/dist"
rm -rf "$APP_DIR" "$ICONSET_DIR" "$ROOT_DIR/dist/PrivateVPNAdmin.app.zip"

pushd "$ROOT_DIR/apps/admin-macos" >/dev/null
swift build -c release
popd >/dev/null

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/apps/admin-macos/.build/arm64-apple-macosx/release/PrivateVPNAdmin" "$MACOS_DIR/PrivateVPNAdmin"
cp "$ROOT_DIR/apps/admin-macos/Support/Info.plist" "$CONTENTS_DIR/Info.plist"

swift "$ROOT_DIR/scripts/render_app_icon.swift" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

pushd "$ROOT_DIR/dist" >/dev/null
ditto -c -k --sequesterRsrc --keepParent PrivateVPNAdmin.app PrivateVPNAdmin.app.zip
popd >/dev/null

echo "Created $ROOT_DIR/dist/PrivateVPNAdmin.app.zip"
