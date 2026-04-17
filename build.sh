#!/bin/bash
APP_NAME="PPToPDF"
APP_DIR="${APP_NAME}.app/Contents"
MACOS_DIR="${APP_DIR}/MacOS"

echo "🎨 ${APP_NAME} 앱을 조립 중입니다..."
mkdir -p "$MACOS_DIR"
mkdir -p "${APP_DIR}/Resources"

echo "🎨 아이콘(.icns)을 렌더링 중입니다..."
if [ -f "RealAppIcon.png" ]; then
    mkdir -p AppIcon.iconset
    sips -z 16 16     RealAppIcon.png --out AppIcon.iconset/icon_16x16.png > /dev/null
    sips -z 32 32     RealAppIcon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null
    sips -z 32 32     RealAppIcon.png --out AppIcon.iconset/icon_32x32.png > /dev/null
    sips -z 64 64     RealAppIcon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null
    sips -z 128 128   RealAppIcon.png --out AppIcon.iconset/icon_128x128.png > /dev/null
    sips -z 256 256   RealAppIcon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null
    sips -z 256 256   RealAppIcon.png --out AppIcon.iconset/icon_256x256.png > /dev/null
    sips -z 512 512   RealAppIcon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null
    sips -z 512 512   RealAppIcon.png --out AppIcon.iconset/icon_512x512.png > /dev/null
    sips -z 1024 1024 RealAppIcon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null
    iconutil -c icns AppIcon.iconset -o "${APP_DIR}/Resources/AppIcon.icns"
    rm -rf AppIcon.iconset
fi

echo "🔨 Swift 소스 코드를 컴파일 중..."
swiftc Source/*.swift -o "$MACOS_DIR/$APP_NAME"

cat > "${APP_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.personal.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>PPT/Word 파일을 PDF로 변환하기 위해 Keynote와 Pages를 제어할 권한이 필요합니다.</string>
</dict>
</plist>
EOF

echo "🔄 LaunchServices 캐시를 갱신 중..."
# mtime 갱신 + LaunchServices 재등록 → Finder/Dock가 새 아이콘을 다시 읽음
touch "${APP_NAME}.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -f "${APP_NAME}.app" > /dev/null 2>&1 || true
fi
killall Dock > /dev/null 2>&1 || true
killall Finder > /dev/null 2>&1 || true

echo "✅ 빌드 성공! 폴더 내에 ${APP_NAME}.app 이 완성되었습니다."
echo "   ※ 아이콘이 여전히 안 보이면 앱을 한 번 실행하거나 다른 폴더로 옮겨보세요."
