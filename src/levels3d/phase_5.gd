extends LevelBase
## Fase 5 — Montanhas: gorilas fortões em bandos. O Gorila Rei aparece numa
## arena cercada de árvores e, a cada 5 s, arremessa duas árvores na sua direção
## (cada uma tira metade da vida): desvie de lado ou pule por cima.

const GorillaScene := preload("res://src/enemies3d/gorilla.tscn")
const BossScene := preload("res://src/enemies3d/gorilla_boss.tscn")

const ROCK := Color(0.5, 0.47, 0.44)


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	bush_colors = [Color(0.2, 0.5, 0.3), Color(0.28, 0.6, 0.35), Color(0.16, 0.42, 0.26)]
	make_arena(ROCK, func(pos, r): make_pine(pos), rng)
	build_arena_content(GorillaScene, rng, Color(0.42, 0.4, 0.38), Color(0.38, 0.36, 0.35),
		[3, 3, 4, 4, 4, 5, 6])
	build_boss(BossScene)
	# várias árvores em volta da arena do chefe (sólidas)
	for i in range(18):
		var ang := TAU * i / 18.0 + rng.randf_range(-0.1, 0.1)
		if sin(ang) > 0.55:
			continue  # deixa a abertura voltada para o resto do mapa
		var r := rng.randf_range(13.0, 17.0)
		var pos := Vector3(BOSS_POINT.x + cos(ang) * r, 0, BOSS_POINT.z + sin(ang) * r * 0.7)
		if absf(pos.x) < HX - 3 and pos.z > -HZ + 3:
			make_tree(pos, Color(0.18 + rng.randf() * 0.06, 0.5, 0.25), true)
