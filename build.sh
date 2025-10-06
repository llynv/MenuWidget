#!/bin/bash

# Simple build script for App Manager macOS utility
# This script assumes Xcode command line tools are installed

echo "Building App Manager macOS utility..."

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Create a temporary Xcode project structure if needed
# For now, we'll just compile the Swift files directly

echo "Compiling Swift files..."

# Compile each Swift file
swiftc -target x86_64-apple-macos10.15 \
    -framework AppKit \
    -framework Foundation \
    -o AppManager \
    AppDelegate.swift \
    ViewController.swift \
    AppCollectionViewItem.swift \
    PreferencesWindowController.swift

if [ $? -eq 0 ]; then
    echo "Build completed successfully!"
    echo "The compiled binary is available as 'AppManager'"
    echo ""
    echo "Note: This is a basic compilation. For a full macOS app with proper"
    echo "bundling, icons, and entitlements, use Xcode to build the project."
else
    echo "Build failed. Please check the error messages above."
    exit 1
fi