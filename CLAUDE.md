# CLAUDE.md — 프로젝트 메모리 (게임)

> 다음 세션이 컨텍스트를 빠르게 잇기 위한 핵심 요약. 작업 전 먼저 읽을 것.

## 프로젝트
**한눈에 보는 성경 이야기 — 항해 (Bible in One Scroll · The Voyage)**
[one-scroll-bible.com](https://one-scroll-bible.com/)(레포 `jungrok5/history`)의 구속사 스크롤을
**Godot 픽셀 게임**으로. 위로 항해하며 창조→타락→…→예수님→회복 기항지를 지나고,
**예수님 항구에서 “사실 해적선에 타고 있었다” 반전** → **항구에서 구조선으로 갈아타며 영접 기도** 엔딩.
- 저장소: `jungrok5/one-scroll-bible-game`
- 사용자 작업 언어: **한국어**

## 콘텐츠 관점 (반드시 준수)
사이트와 동일: **복음주의·개혁주의 구속사 관점, 개역개정 기준.** 성경 인용은 **verbatim(그대로)**.
해적선→배 갈아타기 프레임은 사이트 FAQ a2의 **골 1:13 “옮기셨으니”** 비유에서 가져온 것(임의 창작 아님).
콘텐츠 원본은 `history` 레포 → 추후 `i18n/*.json` 재사용으로 다국어 확장.

## Git 규칙
- 개발 브랜치: **`claude/bible-history-gamification-5i775d`** (여기서 작업·푸시).
- `main` 머지/푸시는 사용자 명시 허락 시에만.
- push: `git push -u origin <branch>`, 네트워크 실패 시 2/4/8/16초 백오프 4회.
- PR은 사용자가 요청할 때만.
- 커밋 메시지 한국어, 끝에 Co-Authored-By(Claude Opus 4.8) / Claude-Session 푸터.
  **모델 식별자(claude-opus-4-8[1m])를 커밋·코드·산출물에 넣지 말 것**(채팅 한정).

## 엔진 / 구조
- **Godot 4.6.3-stable**, GDScript, **GL Compatibility**(웹/모바일 호환).
- 모바일 세로 **360×640**, stretch `canvas_items`/`keep`. 픽셀 스프라이트는 **nearest 필터 + 2배 확대**,
  UI는 캔버스 해상도라 또렷.
- 씬은 `scenes/Main.tscn`(스크립트만) + **월드/UI는 `Main.gd`가 코드로 구성**(엔진 미설치 환경 작성 대비).
- 스크립트: `Main.gd`(월드·항구·연출·엔딩) · `GameData.gd`(콘텐츠 verbatim) · `Player.gd` ·
  `VirtualJoystick.gd` · `DialogueBox.gd` · `fx/LightningFX.gd` · `tools/Autopilot.gd`(E2E).
- 폰트: **Noto Sans KR Bold**(`assets/fonts/*.woff2`). **이모지 미포함 → 텍스트에 이모지 쓰지 말 것**(두부 깨짐).
- 에셋: `assets/sprites/*`는 **임시 플레이스홀더**(`tools/gen_assets.py` 자체 생성) → **Kenney CC0로 교체 예정**.
  교체 시 파일명 동일하게 맞추면 코드 수정 불필요.

## 빌드·테스트 환경 (이 컨테이너에 구축됨)
- Godot: `/usr/local/bin/godot` (4.6.3). 그래픽 라이브러리(mesa)·`xvfb` 설치됨. `LIBGL_ALWAYS_SOFTWARE=1`.
- 익스포트 템플릿: `~/.local/share/godot/export_templates/4.6.3.stable/`
- Android SDK: `/opt/android-sdk`(build-tools;34.0.0, platforms;android-34, platform-tools). JDK 17.
- 디버그 키스토어: `/root/debug.keystore`(pass `android`, alias `androiddebugkey`).
- 에디터 설정(SDK/JDK/키스토어 경로): `~/.config/godot/editor_settings-4.6.tres` 에 주입.
  ⚠ 버전별 파일(`-4.6.tres`)이 `-4.tres`보다 우선 → **import로 먼저 생성 후 주입**할 것.

### 커밋 전 검증(필수)
1. **GDScript 파싱**: `gdparse scripts/*.gd tools/*.gd` (gdtoolkit, `pip install gdtoolkit`).
2. **E2E 오토플레이 + 스크린샷**: `Main`은 환경변수 `E2E`(출력 디렉터리)가 있으면 `Autopilot`을 스폰해
   자동 진행(위로 이동·대화 자동 넘김·기도 버튼 클릭)하며 스크린샷 저장 후 종료. 평상시엔 스폰 안 됨.
   ```
   cd <repo>
   E2E=$PWD/docs/screenshots LIBGL_ALWAYS_SOFTWARE=1 \
     xvfb-run -a -s "-screen 0 720x1280x24" \
     godot --path . --rendering-driver opengl3 --audio-driver Dummy --quit-after 9000
   ```
   캡처본을 **직접 눈으로 확인**(Read)하고, 컨택트시트(`docs/screenshots/_contact_sheet.png`)로 취합.
3. 작업 끝나면 **스크린샷을 깃헙에 커밋**(사용자가 확인).

## APK 빌드 (gradle 빌드 경로 — 검증 완료)
- **ETC2/ASTC 필수**: `project.godot`에 `rendering/textures/vram_compression/import_etc2_astc=true`.
  ⚠ 없으면 헤드리스 export가 **빈 “configuration errors:” 메시지로 실패**(메시지가 안 찍힘). 1순위 의심.
- gradle 빌드 템플릿 설치: `android_source.zip` → `res://android/build/`, `android/.build_version`=`4.6.3.stable`,
  `android/build/.gdignore`(엔진이 템플릿 내부 스캔 막기). `android/`는 **gitignore**(CI가 재설치).
- 익스포트 프리셋 `export_presets.cfg`(name `Android`): `use_gradle_build=true`, `export_format=0`(APK),
  `min_sdk="24"`, `target_sdk="34"`, `arm64-v8a=true`, `package/unique_name="com.onescrollbible.voyage"`.
  ⚠ **프리빌트(use_gradle_build=false) 모드에선 min/target_sdk를 비워야** 함.
- 빌드:
  ```
  ANDROID_HOME=/opt/android-sdk JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 LIBGL_ALWAYS_SOFTWARE=1 \
    xvfb-run -a godot --headless --path . --import
  ANDROID_HOME=/opt/android-sdk JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 LIBGL_ALWAYS_SOFTWARE=1 \
    xvfb-run -a godot --headless --path . --export-debug "Android" build/bible-voyage.apk
  ```
- 서명 검증: `/opt/android-sdk/build-tools/34.0.0/apksigner verify --print-certs build/bible-voyage.apk`.
- 산출물 ~77MB(디버그). 사용자는 **APK 사이드로드로 테스트**.

## CI / 릴리스 규칙 (사용자 요구)
- **`.github/workflows/android.yml`** — 브랜치 push마다 자동으로 두 잡 실행:
  - `build-apk`: Godot/SDK 설치 → APK 빌드 → **GitHub Releases 업로드**(태그 `apk-build-<run>`, prerelease).
  - `deploy-web`: Web(release) export → **`gh-pages` 브랜치 푸시**(peaceiris). 공개 URL: **https://jungrok5.github.io/one-scroll-bible-game/**
    ⚠ `actions/deploy-pages`의 `github-pages` 환경은 **기본 브랜치(main) 전용 보호**라 feature 브랜치에선 즉시 실패 →
    그래서 환경 없는 **gh-pages 브랜치 푸시** 방식 사용. **최초 1회** Settings→Pages→Source: `gh-pages`/(root) 설정 필요.
  - `workflow_dispatch`로 수동 실행도 가능. permissions: contents write.
- **푸시할 때마다 APK가 릴리스에, 웹이 Pages에 갱신돼야 함** — 워크플로 깨지면 최우선 수정. CI 로그는 MCP `actions_*`로 모니터.
- 웹은 **GitHub Pages 제약(COOP/COEP 헤더 불가) → 반드시 `variant/thread_support=false`(싱글스레드)** 로 export.
- 웹 빌드 검증: 로컬에서 `python3 -m http.server` + Playwright Chromium(`/opt/pw-browsers`, `--enable-unsafe-swiftshader`)으로 부팅·렌더 스크린샷 확인(`docs/screenshots/web_*`).

## 함정 / 주의
- **Edit 전 해당 파일을 이 세션에서 Read 必**.
- 헤드리스 export의 “configuration errors:” 빈 메시지 → **ETC2/ASTC, min·target_sdk(모드별), SDK/JDK 경로,
  키스토어** 순으로 점검.
- 스크린샷 등 `docs/`는 `docs/.gdignore`로 엔진 import 제외(불필요한 .import 생성 방지).
- 텍스트에 이모지 금지(폰트 미지원).

## 현재 상태 (2026-06-17)
MVP 수직 슬라이스 완성: 4기항지(창조·타락·예수님[반전]·회복) + 영접 기도 + 배 갈아타기 엔딩.
E2E 오토플레이로 끝까지 동작 확인(스크린샷 `docs/screenshots/`). APK 로컬 빌드 성공·서명 검증 완료.
CI 워크플로 추가. **다음**: 13기항지 확장, 기항지별 연출 강화, 저해상도 뷰포트로 이펙트 통일,
Kenney 에셋 적용, 다국어(i18n) 연동, 웹(HTML5) export.
