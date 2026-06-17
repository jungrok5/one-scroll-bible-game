# 한눈에 보는 성경 이야기 — 항해 (Bible in One Scroll · The Voyage)

[one-scroll-bible.com](https://one-scroll-bible.com/) 의 **구속사 스크롤을 게임화**한
모바일 웹 픽셀 게임. 위로 항해하며 창조→타락→…→예수님→회복의 기항지를 지나고,
**예수님 항구에서 “사실 당신은 해적선에 타고 있었다”는 반전**을 만난 뒤,
**항구에서 구조선으로 갈아타며 영접 기도**로 이어집니다.
(해적선→배 갈아타기 프레임은 사이트 FAQ의 골 1:13 “옮기셨으니” 비유에서 가져옴.)

- **엔진**: Godot 4.x · GDScript · GL Compatibility(웹) · 픽셀(nearest)
- **타깃**: 모바일 세로(270×480 기준), HTML5 export
- **언어**: 한국어(나눔고딕). 본문은 개역개정 verbatim. 추후 다국어(i18n 재사용).

## 실행
1. [Godot 4.x](https://godotengine.org/) 로 이 폴더(`project.godot`)를 엽니다.
   - 첫 실행 시 에셋(PNG/폰트)이 자동 import 됩니다.
2. ▶ 실행(F5). 좌하단 **가상 조이스틱(또는 ↑/↓ · W/S)** 으로 위로 항해.
3. 기항지에 닿으면 말풍선 대화 → 마지막 회복 항구에서 영접 기도 → 엔딩.

## 웹으로 내보내기
`프로젝트 → 내보내기 → Web` 프리셋 추가 후 export. 정적 호스팅(예: 현재 사이트와
같은 Vercel의 `/game` 또는 서브도메인)에 올리면 됩니다.

## 구조
```
project.godot          # 모바일 세로 · nearest · GL Compatibility
scenes/Main.tscn       # 루트(스크립트만; 월드는 코드로 구성)
scripts/
  Main.gd              # 월드 빌드 · 항구 트리거 · 연출 · 영접기도 엔딩 · 배 갈아타기
  GameData.gd          # 콘텐츠(사이트 한국어 verbatim, 기항지/대사/구절/기도)
  Player.gd            # 위/아래 이동
  VirtualJoystick.gd   # 화면 가상 조이스틱
  DialogueBox.gd       # 말풍선 대화창
  fx/LightningFX.gd    # 번개(천지창조 연출)
assets/
  sprites/             # 픽셀 스프라이트(임시 → Kenney CC0로 교체 예정)
  fonts/NanumGothic.woff2
tools/gen_assets.py    # 플레이스홀더 스프라이트 재생성기
docs/style-mockups/    # 스타일 비교 · 연출 데모 이미지
```

## 현재 범위(MVP 수직 슬라이스)
기항지 4곳(창조 · 타락 · 예수님[반전] · 회복) + 영접 기도 엔딩 + 배 갈아타기.
**다음**: 13기항지 전체 확장, 기항지별 연출 강화, 저해상도 뷰포트로 이펙트 통일,
Kenney 에셋 적용, 다국어(i18n) 연동.

## 콘텐츠 관점
한국 개신교 다수의 복음주의·개혁주의 구속사 관점, 개역개정 기준. 성경 인용은 그대로(verbatim).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
