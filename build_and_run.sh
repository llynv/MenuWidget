#!/bin/bash

# Build and Run MenuWidget macOS App
# This script builds the app using Xcode and then launches it

set -e

echo "Building MenuWidget..."
xcodebuild -project MenuWidget.xcodeproj \
    -scheme MenuWidget \
    -configuration Debug \
    build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo "✓ Build succeeded!"
    echo ""
    echo "Launching MenuWidget.app..."

    APP_PATH=~/Library/Developer/Xcode/DerivedData/MenuWidget-*/Build/Products/Debug/MenuWidget.app

    # Kill any existing instance
    killall MenuWidget 2>/dev/null || true

    # Launch the app
    open $APP_PATH

    echo "✓ MenuWidget is now running!"
    echo ""
    echo "Look for the 'App Manager' icon in your menu bar."
    echo "Click it to toggle the app panel."
else
    echo "✗ Build failed. Please check the errors above."
    exit 1
fi

