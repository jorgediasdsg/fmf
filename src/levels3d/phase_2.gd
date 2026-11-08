extends LevelBase
## Fase 2 — Ilha dos Polvos: praia aberta com grupos de polvos que se ajudam
## (e cospem tinta), moitas para se esconder e duas lojinhas. Derrotados todos,
## o Polvo Rei aparece no fundo da ilha.

const OctopusScene := preload("res://src/enemies3d/octopus.tscn")
const BossScene := preload("res://src/enemies3d/octopus_boss.tscn")

const SAND := Color(0.9, 0.76, 0.5)


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	make_water()
	make_arena(SAND, func(pos, r): make_palm(pos, r.randf_range(-8, 8)), rng)
	build_arena_content(OctopusScene, rng, Color(0.95, 0.62, 0.55), Color(0.62, 0.6, 0.7),
		[3, 3, 4, 4, 4, 5, 5])
	build_boss(BossScene)
