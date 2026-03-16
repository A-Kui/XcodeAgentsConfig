#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="kXcodeAgentsConfig"
APP_VERSION="${1:-1.0}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE_PATH="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-$APP_VERSION.dmg"
VOLUME_NAME="$APP_NAME $APP_VERSION"

mkdir -p "$DIST_DIR"
STAGING_DIR="$(mktemp -d "$DIST_DIR/.package_dmg.XXXXXX")"

cleanup() {
    rm -rf "$STAGING_DIR"
}

trap cleanup EXIT

cd "$ROOT_DIR"

"$ROOT_DIR/scripts/package_app.sh" "$APP_VERSION"

rm -f "$DMG_PATH"
cp -R "$APP_BUNDLE_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

echo "Created dmg archive: $DMG_PATH"
