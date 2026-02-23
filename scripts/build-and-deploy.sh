#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Update build number from git commit count
echo "CURRENT_PROJECT_VERSION = $(git rev-list --count HEAD)" > BuildNumber.xcconfig

# Build
xcodebuild build -scheme RechenStar -destination generic/platform=iOS -quiet

# Find built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/RechenStar-*/Build/Products/Debug-iphoneos -name "RechenStar.app" -maxdepth 1 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: RechenStar.app not found in DerivedData"
    exit 1
fi

echo "Installing $APP_PATH"

# Deploy to iPhone (Tom)
xcrun devicectl device install app --device 00008130-0004446200698D3A "$APP_PATH" 2>&1 && echo "iPhone Tom: OK" || echo "iPhone Tom: FAILED (not connected?)"

# Deploy to iPhone (Anina)
# xcrun devicectl device install app --device 5DB9A420-7613-4A26-95FF-577B69D7DAC1 "$APP_PATH" 2>&1 && echo "iPhone Anina: OK" || echo "iPhone Anina: FAILED (not connected?)"

# Deploy to iPad (Fritz)
# xcrun devicectl device install app --device 00008020-001079801440402E "$APP_PATH" 2>&1 && echo "iPad Fritz: OK" || echo "iPad Fritz: FAILED (not connected?)"
