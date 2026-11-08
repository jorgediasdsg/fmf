extends LevelBase
## Fase 3 — Montanha Gelada: neve aberta com grupos de yetis (bem mais vida e
## dano) que se ajudam, moitas de pinheirinho e duas lojinhas. Derrotados
## todos, o Yeti Gigante aparece no topo da montanha.

const YetiScene := preload("res://src/enemies3d/yeti.tscn")
const BossScene := preload("res://src/enemies3d/yeti_boss.tscn")

const SNOW := Color(0.58, 0.7, 0.88)


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	bush_colors = [Color(0.16, 0.55, 0.45), Color(0.22, 0.65, 0.5), Color(0.12, 0.45, 0.4)]
	make_water(-0.4, Color(0.62, 0.82, 0.95))  # lago congelado em volta
	make_arena(SNOW, func(pos, _r): make_pine(pos), rng)
	build_arena_content(YetiScene, rng, Color(0.5, 0.68, 0.9), Color(0.46, 0.56, 0.74),
		[3, 3, 4, 4, 4, 5, 6])
	build_boss(BossScene)
