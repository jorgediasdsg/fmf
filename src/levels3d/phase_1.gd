extends LevelBase
## Fase 1 — Floresta dos Ciclopes: mapa aberto com grupos de ciclopes que se
## ajudam, paredões de pedra, moitas e duas lojinhas. Derrotados todos, o
## Ciclope Grande aparece no fundo do mapa.

const CyclopsScene := preload("res://src/enemies3d/cyclops.tscn")
const BossScene := preload("res://src/enemies3d/cyclops_boss.tscn")


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	make_arena(Color(0.32, 0.5, 0.29),
		func(pos, r): make_tree(pos, Color(0.2 + r.randf() * 0.06, 0.55, 0.26)), rng)
	build_arena_content(CyclopsScene, rng, Color(0.5, 0.52, 0.45), Color(0.58, 0.58, 0.68),
		[3, 3, 3, 3, 4, 4, 5])
	build_boss(BossScene)
