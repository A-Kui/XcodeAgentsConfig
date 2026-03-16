#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="kXcodeAgentsConfig"
APP_VERSION="${1:-1.0}"
BUILD_VERSION="${BUILD_VERSION:-$APP_VERSION}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.k.kXcodeAgentsConfig}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE_PATH="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$APP_VERSION-macOS.zip"
ICON_SOURCE_PATH="$ROOT_DIR/icon.png"
ICON_NAME="AppIcon"

mkdir -p "$DIST_DIR"
TEMP_DIR="$(mktemp -d "$DIST_DIR/.package_app.XXXXXX")"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

cd "$ROOT_DIR"

swift build -c release --product "$APP_NAME"

BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$APP_NAME"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "Release executable not found at $EXECUTABLE_PATH" >&2
    exit 1
fi

if [[ ! -f "$ICON_SOURCE_PATH" ]]; then
    echo "App icon not found at $ICON_SOURCE_PATH" >&2
    exit 1
fi

rm -rf "$APP_BUNDLE_PATH"
mkdir -p "$APP_BUNDLE_PATH/Contents/MacOS" "$APP_BUNDLE_PATH/Contents/Resources"

cp "$EXECUTABLE_PATH" "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
printf 'APPL????' > "$APP_BUNDLE_PATH/Contents/PkgInfo"

# Build a standard macOS .icns from the source PNG so Finder and Launch Services pick it up.
ICONSET_DIR="$TEMP_DIR/$ICON_NAME.iconset"
mkdir -p "$ICONSET_DIR"

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_SOURCE_PATH" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    doubled_size=$((size * 2))
    sips -z "$doubled_size" "$doubled_size" "$ICON_SOURCE_PATH" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE_PATH/Contents/Resources/$ICON_NAME.icns"

cat > "$APP_BUNDLE_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$ICON_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_VERSION</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_BUNDLE_PATH"
fi

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE_PATH" "$ZIP_PATH"

echo "Created app bundle: $APP_BUNDLE_PATH"
echo "Created zip archive: $ZIP_PATH"
