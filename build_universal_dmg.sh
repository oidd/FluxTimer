#!/bin/bash

# FluxTimer 通用架构 (Universal) DMG 打包脚本
# 功能：同时构建 arm64 (M1/M2/M3) 和 x86_64 (Intel) 架构，并生成通用安装包

set -e
# 确保脚本在它所在的目录下运行
cd "$(dirname "$0")"

# 配置
APP_NAME="FluxTimer"
APP_DIR="$(pwd)"
APP_BUNDLE="$APP_DIR/$APP_NAME.app"
DMG_NAME="FluxTimer_Universal_Installer.dmg"
TEMP_DMG="temp_$DMG_NAME"
STAGING_DIR="dmg_staging_universal"

echo "🚀 第一步：清理旧的构建数据..."
rm -rf .build
rm -rf "$APP_NAME.app"

echo "💻 第二步：编译全架构二进制文件 (Universal Binary)..."
echo "这可能需要比平时更长的时间，因为需要编译两次..."
swift build -c release --arch arm64 --arch x86_64

echo "📦 第三步：创建 App Bundle 结构..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 复制生成的通用二进制文件
# swift build --arch arm64 --arch x86_64 会自动在 .build/apple/Products/Release 下生成通用产物
cp ".build/apple/Products/Release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 创建 Info.plist
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
    <false/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

# 复制图标
if [ -f "Sources/Resources/AppIcon.icns" ]; then
    cp "Sources/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# 签名
echo "🔐 第四步：执行 Ad-hoc 签名..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "💿 第五步：生成 DMG 镜像..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -r "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_NAME" "$TEMP_DMG"
hdiutil create -srcfolder "$STAGING_DIR" -volname "$APP_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "$TEMP_DMG"
device=$(hdiutil attach -readwrite -noverify "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 2
hdiutil detach "$device"
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"

# 清理
rm -rf "$STAGING_DIR"
rm -f "$TEMP_DMG"

echo "----------------------------------------------------"
echo "✅ 通用架构打包完成！"
echo "📂 文件位置: $(pwd)/$DMG_NAME"
echo "💻 兼容性：支持 Intel 芯片 + Apple M 芯片"
echo "🖥️ 系统要求：macOS 12.0 及以上"
echo "----------------------------------------------------"
