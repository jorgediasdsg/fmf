extends SceneTree
## Combate 3D (rodar com --headless --fixed-fps 60):
## golpe tira attack_damage; contato tira 2; i-frames; kill dá 8 XP.

var f := 0
var player: CharacterBody3D
var cyclops: CharacterBody3D
var gs: Node
var fails: Array[String] = []
var hp0 := 0
var php := 0
var xp0 := 0


func _initialize() -> void:
	var scene := Node3D.new()
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(60, 1, 60)
	col.shape = shape
	floor_body.add_child(col)
	floor_body.position = Vector3(0, -0.5, 0)
	scene.add_child(floor_body)

	player = (load("res://src/player3d/player.tscn") as PackedScene).instantiate()
	player.position = Vector3.ZERO
	scene.add_child(player)

	cyclops = (load("res://src/enemies3d/cyclops.tscn") as PackedScene).instantiate()
	cyclops.position = Vector3(0, 0, -1.2)  # na frente do player (facing padrão -Z)
	cyclops.set("speed", 0.0)
	scene.add_child(cyclops)

	root.add_child(scene)
	current_scene = scene


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)


func _process(_d) -> bool:
	f += 1
	if gs == null:
		gs = root.get_node("GameState")
	match f:
		10:
			hp0 = cyclops.hp
			Input.action_press("attack")
		12:
			Input.action_release("attack")
		60:
			_check(cyclops.hp == hp0 - gs.attack_damage(),
				"golpe devia tirar %d (hp %d→%d)" % [gs.attack_damage(), hp0, cyclops.hp])
			cyclops.global_position = player.global_position + Vector3(0.3, 0, 0)
		100:
			php = gs.hp
			_check(gs.hp == gs.max_hp - 2, "contato devia tirar 2, hp=%d" % gs.hp)
		130:
			_check(gs.hp == php, "i-frames: hp caiu de novo (%d)" % gs.hp)
			cyclops.global_position = Vector3(10, 0, 0)
			xp0 = gs.xp
			cyclops.take_hit(999, Vector3.ZERO)
		170:
			_check(not is_instance_valid(cyclops) or cyclops.hp <= 0, "ciclope devia morrer")
			_check(gs.xp == xp0 + 8, "kill devia dar 8 XP (era %d, é %d)" % [xp0, gs.xp])
			if fails.is_empty():
				print("COMBAT3D PASSED")
				quit(0)
			else:
				for m in fails:
					print("FAIL: " + m)
				quit(1)
	return false
