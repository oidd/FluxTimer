set -e
# 确保脚本在它所在的目录下运行
cd "$(dirname "$0")"


APP_NAME="FluxTimer"
SOURCES_DIR="Sources"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

# Compile
echo "Compiling..."
swift build -c release

# Create App Bundle Structure
echo "Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy Binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.flux.timer</string>
    <key>CFBundleDisplayName</key>
    <string>FluxTimer</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <false/> <!-- Show in Dock -->
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copy Icon
if [ -f "Sources/Resources/AppIcon.icns" ]; then
    echo "Copying App Icon..."
    cp "Sources/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
else
    echo "Warning: Sources/Resources/AppIcon.icns not found."
fi

# Codesign (Ad-hoc)
echo "Signing App Bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ $APP_NAME.app build complete."
