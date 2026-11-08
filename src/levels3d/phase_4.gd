extends LevelBase
## Fase 4 — Lua: aliens em naves voadoras (3 golpes cada) em bandos que se
## ajudam, cristais para se esconder e duas lojinhas. Derrotados todos, o Alien
## Pai aparece: joga um ovo a cada 5 s (saem 5 mini aliens) e morre com 7 golpes.

const SaucerScene := preload("res://src/enemies3d/alien_saucer.tscn")
const BossScene := preload("res://src/enemies3d/alien_boss.tscn")

const MOON := Color(0.5, 0.5, 0.54)


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	bush_colors = [Color(0.5, 0.35, 0.9), Color(0.3, 0.7, 0.95), Color(0.65, 0.45, 0.95)]
	make_arena(MOON, func(pos, _r): make_rock(pos, Color(0.42, 0.42, 0.52)), rng)
	build_arena_content(SaucerScene, rng, Color(0.5, 0.5, 0.62), Color(0.45, 0.45, 0.56),
		[3, 3, 4, 4, 4, 5, 6])
	build_boss(BossScene)
