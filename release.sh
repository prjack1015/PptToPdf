#!/bin/bash
set -e

APP_NAME="PPToPDF"
VERSION="${1:-1.0.0}"
DIST_DIR="dist"
ZIP_NAME="${APP_NAME}-v${VERSION}.zip"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
STAGING_DIR="${DIST_DIR}/dmg-staging"

echo "📦 ${APP_NAME} v${VERSION} 릴리즈 패키지를 만듭니다..."

# 1. 빌드
bash build.sh

# 2. 코드 서명 우회 도움 (ad-hoc 서명) — Gatekeeper 경고는 남지만 무결성은 보장
codesign --force --deep --sign - "${APP_NAME}.app" 2>/dev/null || true

mkdir -p "${DIST_DIR}"

# 3-A. zip (메타데이터/심볼릭 링크 보존을 위해 ditto 사용)
rm -f "${DIST_DIR}/${ZIP_NAME}"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${DIST_DIR}/${ZIP_NAME}"

# 3-B. dmg (드래그-투-Applications UI)
echo "💿 DMG 패키지를 만듭니다..."
rm -rf "${STAGING_DIR}" "${DIST_DIR}/${DMG_NAME}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_NAME}.app" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DIST_DIR}/${DMG_NAME}" > /dev/null

rm -rf "${STAGING_DIR}"

ZIP_SIZE=$(du -h "${DIST_DIR}/${ZIP_NAME}" | cut -f1)
DMG_SIZE=$(du -h "${DIST_DIR}/${DMG_NAME}" | cut -f1)
echo ""
echo "✅ 패키지 생성 완료:"
echo "   - ${DIST_DIR}/${ZIP_NAME} (${ZIP_SIZE})"
echo "   - ${DIST_DIR}/${DMG_NAME} (${DMG_SIZE})"
echo ""
echo "📤 GitHub Release 업로드 (수동):"
echo "   gh release create v${VERSION} ${DIST_DIR}/${DMG_NAME} ${DIST_DIR}/${ZIP_NAME} --title \"v${VERSION}\" --notes \"...\""
