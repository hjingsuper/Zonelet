#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-dist/Zonelet.app}"
OUTPUT_PATH="${2:-Zonelet-Apple-Silicon.dmg}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "app bundle not found: $APP_PATH" >&2
  exit 1
fi

if [[ "$OUTPUT_PATH" != /* ]]; then
  OUTPUT_PATH="$PWD/$OUTPUT_PATH"
fi

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/zonelet-dmg.XXXXXX")"
cleanup() {
  if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
    rm -rf -- "$STAGING_DIR"
  fi
}
trap cleanup EXIT

ditto "$APP_PATH" "$STAGING_DIR/Zonelet.app"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f -- "$OUTPUT_PATH"

hdiutil create \
  -volname "Zonelet" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$OUTPUT_PATH"
