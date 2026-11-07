extends LevelBase
## Fase 1 — Floresta dos Ciclopes: corredor com 3 clareiras guardadas por
## portões de espinhos e a arena do Ciclope Grande no fim.

const CyclopsScene := preload("res://src/enemies3d/cyclops.tscn")
const BossScene := preload("res://src/enemies3d/cyclops_boss.tscn")

const LENGTH := 92.0
const WIDTH := 14.0


func _ready() -> void:
	super._ready()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	make_ground(Vector3(LENGTH + 8, 1, WIDTH), Color(0.32, 0.5, 0.29), Vector3(LENGTH / 2.0 - 6, 0, 0))
	# paredes invisíveis
	make_wall(Vector3(LENGTH / 2.0 - 6, 2, -WIDTH / 2.0 - 0.5), Vector3(LENGTH + 8, 5, 1))
	make_wall(Vector3(LENGTH / 2.0 - 6, 2, WIDTH / 2.0 + 0.5), Vector3(LENGTH + 8, 5, 1))
	make_wall(Vector3(-10.5, 2, 0), Vector3(1, 5, WIDTH))
	make_wall(Vector3(LENGTH - 1.5, 2, 0), Vector3(1, 5, WIDTH))

	# árvores nas bordas + pedras
	var x := -8.0
	while x < LENGTH - 4:
		if absf(fmod(x, 20.0) - 10.0) > 2.5:  # deixa vão nos portões
			make_tree(Vector3(x, 0, -WIDTH / 2.0 + rng.randf_range(0.6, 1.6)),
				Color(0.14 + rng.randf() * 0.06, 0.36, 0.2))
			make_tree(Vector3(x + 2.1, 0, WIDTH / 2.0 - rng.randf_range(0.6, 1.6)),
				Color(0.14 + rng.randf() * 0.06, 0.36, 0.2))
		x += 4.3
	for i in range(8):
		make_rock(Vector3(rng.randf_range(2, LENGTH - 8), 0, rng.randf_range(-4.5, 4.5)))

	# clareiras: (centro x, qtd inimigos, portão x)
	var zones := [[10.0, 2, 20.0], [30.0, 3, 40.0], [50.0, 4, 60.0]]
	for z in zones:
		var enemies: Array = []
		for i in range(z[1]):
			var c := CyclopsScene.instantiate()
			c.position = Vector3(z[0] + rng.randf_range(-3, 3), 0.1, rng.randf_range(-4, 4))
			add_child(c)
			enemies.append(c)
		_register_zone(enemies, make_gate(Vector3(z[2], 0, 0), WIDTH))

	# chefe
	var boss := BossScene.instantiate()
	boss.position = Vector3(76, 0.1, 0)
	add_child(boss)
	_register_boss(boss)
