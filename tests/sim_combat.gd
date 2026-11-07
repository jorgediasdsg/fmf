extends SceneTree
## Simulação de combate (rodar com --fixed-fps 60 --headless):
## 1. golpe tira exatamente gs.attack_damage() do ciclope
## 2. contato causa 2 de dano no jogador
## 3. i-frames: contato contínuo não re-dana dentro de 1 s
## 4. matar o ciclope credita 8 de XP

var f := 0
var player: CharacterBody2D
var cyclops: CharacterBody2D
var fails: Array[String] = []
var hp_before_hit := 0
var player_hp_after_first := 0
var xp_before_kill := 0
var gs: Node


func _initialize() -> void:
	var scene := Node2D.new()
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(600, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(300, 110)
	scene.add_child(floor_body)

	player = (load("res://src/player/player.tscn") as PackedScene).instantiate()
	player.position = Vector2(100, 99)
	scene.add_child(player)

	cyclops = (load("res://src/enemies/cyclops.tscn") as PackedScene).instantiate()
	cyclops.position = Vector2(130, 95)
	cyclops.set("speed", 0.0)  # parado para o teste ser determinístico
	scene.add_child(cyclops)

	root.add_child(scene)
	current_scene = scene


func _ensure_gs() -> void:
	if gs == null:
		gs = root.get_node("GameState")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)


func _process(_d) -> bool:
	f += 1
	_ensure_gs()
	match f:
		5:
			hp_before_hit = cyclops.hp
			Input.action_press("attack")  # player olha para +x, ciclope à direita
		7:
			Input.action_release("attack")
		30:
			_check(cyclops.hp == hp_before_hit - gs.attack_damage(),
				"golpe devia tirar %d, hp foi %d→%d" % [gs.attack_damage(), hp_before_hit, cyclops.hp])
			# 2) contato: ciclope em cima do player
			cyclops.position = player.position + Vector2(4, -4)
		60:
			player_hp_after_first = gs.hp
			_check(gs.hp == gs.max_hp - 2,
				"contato devia tirar 2, hp é %d" % gs.hp)
		90:
			_check(gs.hp == player_hp_after_first,
				"i-frames: hp não devia cair de novo (é %d)" % gs.hp)
			# afasta e prepara kill
			cyclops.position = Vector2(400, 95)
			xp_before_kill = gs.xp
			cyclops.take_hit(999, 1.0)
		120:
			_check(not is_instance_valid(cyclops) or cyclops.hp <= 0, "ciclope devia morrer")
			_check(gs.xp == xp_before_kill + 8,
				"matar devia dar 8 XP (xp era %d, é %d)" % [xp_before_kill, gs.xp])
			if fails.is_empty():
				print("COMBAT SIM PASSED")
				quit(0)
			else:
				for m in fails:
					print("FAIL: " + m)
				quit(1)
	return false
