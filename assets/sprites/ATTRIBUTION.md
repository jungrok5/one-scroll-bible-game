# 에셋 출처 / 라이선스

## Kenney (CC0 · 퍼블릭 도메인) — 적용됨
- **Tiny Town** (https://kenney.nl/assets/tiny-town) — 잔디/흙/돌 타일, 나무·덤불·버섯·간판·성벽·통
- **Tiny Dungeon** (https://kenney.nl/assets/tiny-dungeon) — 캐릭터(플레이어=후드 여행자, 안내자=마법사, NPC들)
  16×16 픽셀, 동일 아티스트 패밀리라 톤 일치. CC0라 표기 의무 없으나 감사 차원 기록.
- 매핑: player←TD98, guide←TD84, npc_teal←TD112, npc_red←TD111, npc_purple←TD99,
  tree←TT4, tree2←TT7, bush←TT5, sign←TT83, citywall←TT97, deadtree←TT9, mushroom←TT29, barrel←TT106,
  tile_grass←TT0, tile_dirt←TT25, tile_stone←TT108.

## 자체 제작(임시) — 일부 유지
ship_pirate/ship_rescue, cross, pillar, serpent, reed, lily, flower_*, lantern, dot, vignette,
tile_water, tile_plank, tile_sand, sparkle = `tools/gen_assets.py`(순수 파이썬) 생성.
⚠ gen_assets.py 재실행 시 Kenney로 교체한 파일을 덮어쓰지 말 것(현재는 위 파일만 갱신되도록 사용).

## 폰트
`assets/fonts/NotoSansKR-Bold.woff2` — Noto Sans KR Bold, OFL.

## Ninja Adventure (CC0) — 적용됨 (캐릭터·UI·뱀)
- pixel-boy/AAA, https://pixel-boy.itch.io/ninja-adventure-asset-pack (CC0).
- 캐릭터(정면 프레임): player←char25, guide(노인)←char9, npc_teal←char3, npc_red←char14, npc_purple←char2.
- serpent←monster21. UI: assets/ui/bubble.png(말풍선/대화창 9-slice), faceset_box.png, panel.png.
- 초상(faceset): assets/face/guide.png(char9), player.png(char25).
- 미러: github.com/sparklinlabs/superpowers-asset-packs/ninja-adventure
- 남은 혼용(추후 NA로 통일 가능): 바닥/물 타일(Kenney Tiny), 배·십자가·기둥(자체 제작).
