class_name GameData
extends RefCounted
#
# 콘텐츠 데이터 — one-scroll-bible.com 본문(개역개정) 기반. 성경 인용 verbatim.
# 항해/해적 프레임은 사이트 FAQ a2(골 1:13 "옮기셨으니")에서 가져옴.
# RPG 모델: 섬을 돌아다니며 NPC 근처에서 머리 위 말풍선. 클라이맥스(반전)·엔딩(기도)만 모달.
#
# biome: 씬별 배경(바다/땅/가장자리/길 색 + 소품 decor).
# npcs:  머리 위 말풍선 [{spr,x,yo,text}]. guide=등불 안내자(예수님 실).

static func stops() -> Array:
	return [
		{
			"key": "creation", "title": "창조", "tag": "구약 · 시작",
			"one": "하나님이 보시기에 “심히 좋은” 세상을 지으셨다.",
			"fx": "creation", "shard": "말씀",
			"biome": {
				"sea_tint": Color(0.95, 1.08, 1.12), "ground_tile": "tile_grass.png", "ground_tint": Color(1, 1, 1),
				"edge": Color8(226, 208, 150), "title_color": Color8(180, 240, 200),
				"decor": [["tree.png", 286, -112], ["tree2.png", 70, 120], ["bush.png", 300, 72],
					["flower_y.png", 56, -60], ["flower_w.png", 300, -40], ["bush.png", 250, 130], ["flower_r.png", 92, 58]],
			},
			"npcs": [
				{"spr": "sign.png", "x": 78, "yo": -10, "text": "“태초에 하나님이 천지를 창조하시니라” — 창세기 1:1"},
				{"spr": "npc_teal.png", "x": 116, "yo": 20, "text": "엿새 동안 빛과 바다와 생명을 지으시고, 사람을 하나님의 형상대로 지으셨어요."},
				{"spr": "guide.png", "x": 300, "yo": 14, "guide": true, "text": "이 세상은 ‘말씀’으로 지어졌습니다. 그 말씀이 곧 예수님이세요. (요 1:1-3)"},
			],
		},
		{
			"key": "fall", "title": "타락", "tag": "구약 · 문제의 시작",
			"one": "죄가 들어와 사람과 하나님 사이가 끊어졌다.",
			"fx": "fall", "shard": "여자의 후손",
			"biome": {
				"sea_tint": Color(0.72, 0.82, 0.88), "ground_tile": "tile_grass.png", "ground_tint": Color(0.74, 0.78, 0.6),
				"edge": Color8(150, 140, 110), "title_color": Color8(210, 170, 160),
				"decor": [["deadtree.png", 286, -110], ["deadtree.png", 64, 112], ["rock.png", 300, 60],
					["reed.png", 250, 130], ["serpent.png", 280, -48], ["mushroom.png", 80, -40]],
			},
			"npcs": [
				{"spr": "sign.png", "x": 78, "yo": -10, "text": "“여자의 후손은 네 머리를 상하게 할 것이요” — 창세기 3:15"},
				{"spr": "npc_red.png", "x": 116, "yo": 20, "text": "아담과 하와가 선악과를 먹고 에덴에서 쫓겨났습니다… 죽음과 수고가 들어왔죠."},
				{"spr": "guide.png", "x": 300, "yo": 14, "guide": true, "text": "심판 한가운데 주신 첫 복음의 약속이에요. 여자의 후손이 뱀의 머리를 깨뜨릴 것 — 예수님이세요."},
			],
		},
		{
			"key": "jesus", "title": "예수님의 오심", "tag": "신약 · 성취",
			"one": "약속하신 메시아가 오셔서, 죽고, 다시 살아나셨다.",
			"fx": "jesus", "reveal": true,
			"biome": {
				"sea_tint": Color(0.66, 0.8, 0.98), "ground_tile": "tile_stone.png", "ground_tint": Color(0.92, 0.92, 0.97),
				"edge": Color8(162, 162, 168), "title_color": Color8(255, 244, 200),
				"decor": [["pillar.png", 64, -96], ["pillar.png", 296, -96], ["pillar.png", 64, 112], ["pillar.png", 296, 112],
					["cross.png", 180, -88], ["ship_pirate.png", 286, 122]],
			},
			"npcs": [
				{"spr": "sign.png", "x": 78, "yo": -10, "text": "“말씀이 육신이 되어 우리 가운데 거하시매 은혜와 진리가 충만하더라” — 요한복음 1:14"},
				{"spr": "npc_purple.png", "x": 116, "yo": 20, "text": "약속하신 메시아가 오셔서, 죽고, 다시 살아나셨습니다."},
				{"spr": "guide.png", "x": 300, "yo": 14, "guide": true, "text": "여자의 후손·아브라함의 복·유월절 양·다윗의 왕 — 모두 이 한 분 안에서 이뤄집니다."},
			],
			"reveal_lines": [
				{"speaker": "안내자", "text": "그런데… 당신이 타고 온 저 배를 보세요."},
				{"speaker": "안내자", "text": "검은 깃발. 당신은 줄곧 ‘해적선’에 타고 있었습니다."},
				{"speaker": "안내자", "text": "갑판을 아무리 닦아도 그 배는 심판의 항구로 향합니다. 문제는 행동이 아니라 ‘어느 배에 속했는가’예요."},
				{"speaker": "안내자", "text": "그래서 복음은 “더 착해져라”가 아니라 — “배를 옮겨 타라”입니다. (골 1:13)"},
			],
		},
		{
			"key": "restoration", "title": "회복", "tag": "신약 · 완성",
			"one": "예수님이 다시 오셔서 모든 것을 새롭게 하신다.",
			"fx": "restoration", "ending": true,
			"biome": {
				"sea_tint": Color(0.98, 1.12, 1.06), "ground_tile": "tile_grass.png", "ground_tint": Color(1.16, 1.08, 0.8),
				"edge": Color8(238, 226, 172), "title_color": Color8(255, 236, 170),
				"decor": [["citywall.png", 70, -112], ["citywall.png", 290, -112], ["citywall.png", 180, -122],
					["tree.png", 296, 70], ["flower_w.png", 60, 60], ["ship_rescue.png", 180, -120]],
			},
			"npcs": [
				{"spr": "sign.png", "x": 78, "yo": -10, "text": "“모든 눈물을 그 눈에서 닦아 주시니 다시는 사망이 없고…” — 요한계시록 21:4"},
				{"spr": "guide.png", "x": 300, "yo": 14, "guide": true, "text": "저기 빛나는 구조선이 당신을 기다립니다. 손 내미시는 그분께, 이제 건너오시겠어요?"},
			],
		},
	]


static func prayer_lines() -> Array:
	return [
		"하나님,",
		"저는 스스로를 구원할 수 없는 죄인임을 인정합니다.",
		"예수님이 저를 위해 십자가에서 죽으시고 다시 살아나신 것을 믿습니다.",
		"제 모든 죄를 용서해 주시고, 이제 제 삶의 주인이 되어 주세요.",
		"저를 하나님의 자녀로 받아 주시고, 새로운 삶을 살게 해 주세요.",
		"예수님의 이름으로 기도합니다. 아멘.",
	]


static func after_text() -> String:
	return "이 기도를 진심으로 드렸다면, 성경은 당신이 하나님의 자녀가 되었다고 말합니다. 이제 혼자가 아닙니다 — 가까운 교회를 찾아 함께 신앙의 길을 걸어가세요."


static func after_verse() -> String:
	return "“영접하는 자 곧 그 이름을 믿는 자들에게는 하나님의 자녀가 되는 권세를 주셨으니” — 요 1:12 (개역개정)"


const SITE_URL := "https://one-scroll-bible.com/"
