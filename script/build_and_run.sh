#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Zonelet"
BUNDLE_ID="${ZONELET_BUNDLE_ID:-com.local.Zonelet}"
MIN_SYSTEM_VERSION="14.0"
BUILD_CONFIGURATION="${ZONELET_CONFIGURATION:-debug}"
SIGNING_IDENTITY="${ZONELET_SIGNING_IDENTITY:--}"
SIGNING_TIMESTAMP="${ZONELET_SIGNING_TIMESTAMP:-1}"
DISABLE_LIBRARY_VALIDATION="${ZONELET_DISABLE_LIBRARY_VALIDATION:-0}"
APP_VERSION="${ZONELET_VERSION:-1.11}"
APP_BUILD="${ZONELET_BUILD_NUMBER:-27}"
SPARKLE_PUBLIC_KEY="i9H5HUPmZ02/s3+M+a7SIPYxvZgEHFEkHOcTtoQtIK0="
SPARKLE_FEED_URL="https://github.com/hjingsuper/Zonelet/releases/latest/download/appcast.xml"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Assets/AppIcon.icns"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build -c "$BUILD_CONFIGURATION"
BUILD_DIR="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"
SPARKLE_FRAMEWORK="$BUILD_DIR/Sparkle.framework"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_FRAMEWORKS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
ditto "$SPARKLE_FRAMEWORK" "$APP_FRAMEWORKS/Sparkle.framework"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
chmod +x "$APP_BINARY"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>SUFeedURL</key>
  <string>$SPARKLE_FEED_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_KEY</string>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUAutomaticallyUpdate</key>
  <true/>
  <key>SUScheduledCheckInterval</key>
  <integer>21600</integer>
</dict>
</plist>
PLIST

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  codesign --force --sign - "$APP_BUNDLE" >/dev/null
else
  SIGNING_ARGS=(--force --options runtime)
  if [[ "$SIGNING_TIMESTAMP" == "1" ]]; then
    SIGNING_ARGS+=(--timestamp)
  fi
  SPARKLE_PATH="$APP_FRAMEWORKS/Sparkle.framework/Versions/B"
  codesign "${SIGNING_ARGS[@]}" --sign "$SIGNING_IDENTITY" \
    "$SPARKLE_PATH/XPCServices/Installer.xpc"
  codesign "${SIGNING_ARGS[@]}" --preserve-metadata=entitlements \
    --sign "$SIGNING_IDENTITY" "$SPARKLE_PATH/XPCServices/Downloader.xpc"
  codesign "${SIGNING_ARGS[@]}" --sign "$SIGNING_IDENTITY" \
    "$SPARKLE_PATH/Autoupdate"
  codesign "${SIGNING_ARGS[@]}" --sign "$SIGNING_IDENTITY" \
    "$SPARKLE_PATH/Updater.app"
  codesign "${SIGNING_ARGS[@]}" --sign "$SIGNING_IDENTITY" \
    "$APP_FRAMEWORKS/Sparkle.framework"
  if [[ "$DISABLE_LIBRARY_VALIDATION" == "1" ]]; then
    APP_ENTITLEMENTS="$DIST_DIR/$APP_NAME.entitlements"
    cat >"$APP_ENTITLEMENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.cs.disable-library-validation</key>
  <true/>
</dict>
</plist>
PLIST
    codesign "${SIGNING_ARGS[@]}" \
      --entitlements "$APP_ENTITLEMENTS" \
      --sign "$SIGNING_IDENTITY" \
      "$APP_BUNDLE"
  else
    codesign "${SIGNING_ARGS[@]}" \
      --sign "$SIGNING_IDENTITY" \
      "$APP_BUNDLE"
  fi
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --package|package)
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--package|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
