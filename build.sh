#!/bin/sh
set -e
cd "$(dirname "$0")"

# locationd remembers the permission by bundle path for ad hoc signed apps, so always install to the same place
INSTALL=/Applications/WeatherBar.app
APP=$(mktemp -d)/WeatherBar.app
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

ICONSET=$(mktemp -d)/AppIcon.iconset
swift make_icon.swift "$ICONSET"
iconutil -c icns -o "$APP/Contents/Resources/AppIcon.icns" "$ICONSET"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>local.weatherbar.menubar</string>
    <key>CFBundleName</key><string>WeatherBar</string>
    <key>CFBundleExecutable</key><string>WeatherBar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSLocationUsageDescription</key><string>WeatherBar uses your location to show the local weather.</string>
    <key>NSLocationWhenInUseUsageDescription</key><string>WeatherBar uses your location to show the local weather.</string>
</dict>
</plist>
PLIST

swiftc -O -swift-version 5 -o "$APP/Contents/MacOS/WeatherBar" WeatherBar.swift
codesign --force --sign - "$APP"

pkill -x WeatherBar || true
rm -rf "$INSTALL"
mv "$APP" "$INSTALL"
open "$INSTALL"
echo "Installed and launched $INSTALL"
