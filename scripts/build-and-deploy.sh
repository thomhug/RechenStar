#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# --- Build Number Logic ---
# Read last known TestFlight build number
TF_BUILD_FILE=".testflight-build-number"
if [ -f "$TF_BUILD_FILE" ]; then
    TF_BUILD=$(cat "$TF_BUILD_FILE" | tr -d '[:space:]')
else
    TF_BUILD=0
    echo "$TF_BUILD" > "$TF_BUILD_FILE"
fi
NEXT_TF=$((TF_BUILD + 1))

# Track local build count (resets when TF base changes)
LOCAL_COUNT_FILE=".local-build-count"
if [ -f "$LOCAL_COUNT_FILE" ]; then
    STORED_BASE=$(head -1 "$LOCAL_COUNT_FILE")
    STORED_COUNT=$(tail -1 "$LOCAL_COUNT_FILE")
    if [ "$STORED_BASE" = "$NEXT_TF" ]; then
        LOCAL_COUNT=$((STORED_COUNT + 1))
    else
        LOCAL_COUNT=1
    fi
else
    LOCAL_COUNT=1
fi
printf "%s\n%s" "$NEXT_TF" "$LOCAL_COUNT" > "$LOCAL_COUNT_FILE"

# Build number: e.g. "1.1", "1.2" — dots required by Apple CFBundleVersion format
BUILD_NUMBER="${NEXT_TF}.${LOCAL_COUNT}"

cat > BuildNumber.xcconfig <<EOF
CURRENT_PROJECT_VERSION = ${BUILD_NUMBER}
IS_LOCAL_BUILD = YES
EOF

echo "Local Build: ${BUILD_NUMBER} (TestFlight base: ${TF_BUILD})"

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

# Deploy to iPad (Fritz)
# xcrun devicectl device install app --device 00008020-001079801440402E "$APP_PATH" 2>&1 && echo "iPad Fritz: OK" || echo "iPad Fritz: FAILED (not connected?)"
