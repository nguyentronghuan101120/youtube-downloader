#!/bin/bash

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build macOS release
flutter build macos --release

# Create DMG
cd build/macos/Build/Products/Release
create-dmg \
  --volname "YouTube Downloader" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "YouTube Downloader.app" 200 190 \
  --hide-extension "YouTube Downloader.app" \
  --app-drop-link 600 185 \
  "YouTube Downloader.dmg" \
  "YouTube Downloader.app"

echo "Build completed! DMG file is located at: build/macos/Build/Products/Release/YouTube Downloader.dmg" 