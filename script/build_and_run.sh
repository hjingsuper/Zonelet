#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Zonelet"
BUNDLE_ID="${ZONELET_BUNDLE_ID:-com.hjingsuper.ZoneletApp}"
MIN_SYSTEM_VERSION="14.0"
BUILD_CONFIGURATION="${ZONELET_CONFIGURATION:-debug}"
DISTRIBUTION_BUILD="${ZONELET_DISTRIBUTION_BUILD:-0}"
SPARKLE_PUBLIC_KEY="i9H5HUPmZ02/s3+M+a7SIPYxvZgEHFEkHOcTtoQtIK0="
SPARKLE_FEED_URL="https://github.com/hjingsuper/Zonelet/releases/latest/download/appcast.xml"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_APP_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
DEFAULT_APP_BUILD="$(tr -d '[:space:]' < "$ROOT_DIR/BUILD_NUMBER")"
APP_VERSION="${ZONELET_VERSION:-$DEFAULT_APP_VERSION}"
APP_BUILD="${ZONELET_BUILD_NUMBER:-$DEFAULT_APP_BUILD}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Assets/AppIcon.icns"

if [[ ! "$APP_VERSION" =~ ^[0-9]+([.][0-9]+){1,2}$ ]]; then
  echo "invalid Zonelet version: $APP_VERSION" >&2
  exit 2
fi
if [[ ! "$APP_BUILD" =~ ^[1-9][0-9]*$ ]]; then
  echo "invalid Zonelet build number: $APP_BUILD" >&2
  exit 2
fi
if [[ "$DISTRIBUTION_BUILD" != "0" && "$DISTRIBUTION_BUILD" != "1" ]]; then
  echo "ZONELET_DISTRIBUTION_BUILD must be 0 or 1" >&2
  exit 2
fi

DISTRIBUTION_BUILD_PLIST="<false/>"
if [[ "$DISTRIBUTION_BUILD" == "1" ]]; then
  DISTRIBUTION_BUILD_PLIST="<true/>"
fi

cd "$ROOT_DIR"
if [[ "$MODE" == "run" ]]; then
  while IFS= read -r app_pid; do
    app_command="$(ps -p "$app_pid" -o command= 2>/dev/null || true)"
    if [[ "$app_command" == "$APP_BINARY" || "$app_command" == "$APP_BINARY "* ]]; then
      kill "$app_pid" >/dev/null 2>&1 || true
    fi
  done < <(pgrep -x "$APP_NAME" || true)
fi

swift build -c "$BUILD_CONFIGURATION"
BUILD_DIR="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"
SPARKLE_FRAMEWORK="$BUILD_DIR/Sparkle.framework"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_FRAMEWORKS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
ditto "$SPARKLE_FRAMEWORK" "$APP_FRAMEWORKS/Sparkle.framework"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
cp "$ROOT_DIR/LICENSE" "$APP_RESOURCES/Zonelet-LICENSE.txt"
cp "$ROOT_DIR/.build/checkouts/Sparkle/LICENSE" "$APP_RESOURCES/Sparkle-LICENSE.txt"
mkdir -p "$APP_RESOURCES/zh_CN.lproj" "$APP_RESOURCES/zh-Hans.lproj" "$APP_RESOURCES/en.lproj"
cat >"$APP_RESOURCES/zh_CN.lproj/InfoPlist.strings" <<'STRINGS'
"CFBundleDisplayName" = "Zonelet";
"CFBundleName" = "Zonelet";
STRINGS
cp "$APP_RESOURCES/zh_CN.lproj/InfoPlist.strings" "$APP_RESOURCES/zh-Hans.lproj/InfoPlist.strings"
cat >"$APP_RESOURCES/en.lproj/InfoPlist.strings" <<'STRINGS'
"CFBundleDisplayName" = "Zonelet";
"CFBundleName" = "Zonelet";
STRINGS
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
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>zh-Hans</string>
    <string>zh_CN</string>
    <string>en</string>
  </array>
  <key>CFBundleAllowMixedLocalizations</key>
  <true/>
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
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 hjingsuper</string>
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
  <key>ZoneletDistributionBuild</key>
  $DISTRIBUTION_BUILD_PLIST
</dict>
</plist>
PLIST

# Zonelet intentionally ships without an Apple Developer certificate.
# Sparkle still verifies downloaded updates with its separate EdDSA signature.
codesign --force --sign - "$APP_BUNDLE" >/dev/null

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
