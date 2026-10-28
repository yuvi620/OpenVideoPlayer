#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "  OpenVideoPlayer IPA Builder for macOS   "
echo "=========================================="

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Error: This script must be executed on macOS with Xcode installed."
  echo "Current OS: $OSTYPE"
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

OUTPUT_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$OUTPUT_DIR/OpenVideoPlayer.xcarchive"
PAYLOAD_DIR="$OUTPUT_DIR/Payload"
IPA_PATH="$OUTPUT_DIR/OpenVideoPlayer.ipa"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "==> 1. Building and Archiving (Release)..."
xcodebuild archive \
  -project OpenVideoPlayer.xcodeproj \
  -scheme OpenVideoPlayer \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo "==> 2. Packaging Application Bundle into IPA Payload..."
mkdir -p "$PAYLOAD_DIR"
cp -r "$ARCHIVE_PATH/Products/Applications/OpenVideoPlayer.app" "$PAYLOAD_DIR/"

echo "==> 3. Creating IPA archive..."
cd "$OUTPUT_DIR"
zip -qr "$IPA_PATH" Payload/

echo "=========================================="
echo "SUCCESS: IPA generated at:"
echo "$IPA_PATH"
echo "=========================================="
echo "You can now sign and install this IPA using:"
echo " - Sideloadly (Mac or Windows)"
echo " - AltStore / AltServer"
echo " - TrollStore (if iOS version compatible)"
echo " - Xcode Devices & Simulators window"
