# PPToPDF

PPT·Word 파일을 **PDF로 일괄 변환**해주는 macOS 앱입니다.
드래그 앤 드롭만으로 여러 파일을 한 번에 변환할 수 있어요.

지원 포맷: `.ppt` `.pptx` `.doc` `.docx` → `.pdf`

---

## 다운로드 & 실행

### 1. 다운로드

[Releases 페이지](https://github.com/prjack1015/PptToPdf/releases/latest)에서 다음 둘 중 편한 형식을 받습니다.

- **`PPToPDF-vX.X.X.dmg`** (권장) — 더블클릭으로 열어 `PPToPDF.app`을 `Applications` 폴더로 드래그
- **`PPToPDF-vX.X.X.zip`** — 압축을 풀어 원하는 위치에 `PPToPDF.app`을 둠

### 2. 첫 실행 (중요)

이 앱은 Apple 코드 서명이 되어 있지 않아 처음 실행할 때 macOS가 막을 수 있습니다.

**Finder에서 `PPToPDF.app`을 우클릭 → "열기" → 경고창에서 다시 "열기"** 를 누르면 이후부터는 일반 앱처럼 더블클릭으로 실행됩니다.

> "확인되지 않은 개발자가 배포했기 때문에 열 수 없습니다" 경고가 떠도 정상입니다.
> 시스템 설정 → "개인정보 보호 및 보안" 맨 아래에서도 "확인 없이 열기"를 누를 수 있습니다.

### 3. 자동화 권한 허용

첫 변환 시 macOS가 **Keynote / Pages를 제어해도 되는지** 묻는 다이얼로그를 띄웁니다. "허용"을 눌러야 변환이 동작합니다.
(이 앱은 Keynote/Pages의 PDF 내보내기 기능을 이용해 변환합니다 — Keynote/Pages가 미리 설치되어 있어야 해요.)

---

## 사용법

1. 앱을 실행하면 빈 영역이 나옵니다.
2. PPT/Word 파일을 **드래그해서 떨어뜨리거나**, 툴바의 **"파일 추가"** 버튼으로 선택합니다.
3. 우상단에서:
   - **"다운로드로 변환"** → `~/Downloads`에 즉시 저장
   - **"폴더 선택..."** → 원하는 위치에 저장
4. 각 파일 옆 아이콘으로 진행 상황을 확인할 수 있습니다 (대기 / 변환 중 / ✅ / ❌).
5. ❌ 표시 위에 마우스를 올리면 실패 원인이 표시됩니다.

---

## 시스템 요구사항

- macOS 11 (Big Sur) 이상
- Keynote (PPT 변환용) / Pages (Word 변환용) — App Store에서 무료 설치

---

## 개발자용 — 직접 빌드하기

```bash
git clone https://github.com/prjack1015/PptToPdf.git
cd PptToPdf
bash build.sh
open PPToPDF.app
```

릴리즈 패키지(zip + dmg) 만들기:

```bash
bash release.sh 1.0.0
# → dist/PPToPDF-v1.0.0.zip
# → dist/PPToPDF-v1.0.0.dmg
```

### 프로젝트 구조

```text
Source/
  AppMain.swift          # SwiftUI 엔트리
  ContentView.swift      # UI (드래그 앤 드롭 / 툴바 / 리스트)
  ConversionEngine.swift # 변환 큐 + AppleScript 자동화
build.sh                 # swiftc 직접 컴파일 → .app 번들 조립
release.sh               # 빌드 + 서명 + ditto/hdiutil → dist/*.{zip,dmg}
```

---

## 동작 원리

이 앱은 **자체적으로 PDF를 만들지 않습니다.** 대신 macOS에 설치된 Keynote / Pages를 AppleScript로 백그라운드에서 띄워, 그쪽의 "PDF로 내보내기" 기능을 호출합니다. 그래서:

- ✅ 변환 품질이 Keynote/Pages 자체와 동일 (폰트·애니메이션 정적 캡처 그대로)
- ⚠️ Keynote/Pages가 설치되어 있어야 함
- ⚠️ 변환 중 Keynote/Pages 창이 잠깐 떴다 사라질 수 있음

---

## 라이선스

개인 사용 자유. 상업적 활용/재배포 시에는 이슈로 문의해 주세요.
