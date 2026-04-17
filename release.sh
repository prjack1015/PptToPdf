#!/bin/bash
set -e

APP_NAME="PPToPDF"
VERSION="${1:-1.0.0}"
DIST_DIR="dist"
ZIP_NAME="${APP_NAME}-v${VERSION}.zip"

echo "📦 ${APP_NAME} v${VERSION} 릴리즈 패키지를 만듭니다..."

# 1. 빌드
bash build.sh

# 2. 코드 서명 우회 도움 (ad-hoc 서명) — Gatekeeper 경고는 남지만 무결성은 보장
codesign --force --deep --sign - "${APP_NAME}.app" 2>/dev/null || true

# 3. 압축 (메타데이터/심볼릭 링크 보존을 위해 zip 대신 ditto 사용)
mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}/${ZIP_NAME}"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${DIST_DIR}/${ZIP_NAME}"

SIZE=$(du -h "${DIST_DIR}/${ZIP_NAME}" | cut -f1)
echo "✅ ${DIST_DIR}/${ZIP_NAME} (${SIZE}) 생성 완료"
echo ""
echo "📤 GitHub Release 업로드 (수동):"
echo "   gh release create v${VERSION} ${DIST_DIR}/${ZIP_NAME} --title \"v${VERSION}\" --notes \"...\""
