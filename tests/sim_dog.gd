extends SceneTree
## Cachorro: segue o Zack de perto; investe num inimigo próximo e causa 2 de dano.

var f := 0
var player: CharacterBody3D
var dog: CharacterBody3D
var cyclops: CharacterBody3D
var fails: Array[String] = []


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
	scene.add_child(player)

	dog = (load("res://src/player3d/dog.tscn") as PackedScene).instantiate()
	dog.position = Vector3(1, 0, 1)
	scene.add_child(dog)

	cyclops = (load("res://src/enemies3d/cyclops.tscn") as PackedScene).instantiate()
	cyclops.position = Vector3(5, 0, 0)
	cyclops.set("speed", 0.0)
	scene.add_child(cyclops)

	root.add_child(scene)
	current_scene = scene


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)


func _process(_d) -> bool:
	f += 1
	if f == 120:
		_check(dog.global_position.distance_to(player.global_position) < 3.0,
			"cachorro devia ficar perto do Zack (dist %.1f)" % dog.global_position.distance_to(player.global_position))
	if f == 300:
		_check(cyclops.hp <= 4, "ciclope devia ter levado mordida (hp=%d)" % cyclops.hp)
		if fails.is_empty():
			print("DOG SIM PASSED")
			quit(0)
		else:
			for m in fails:
				print("FAIL: " + m)
			quit(1)
	return false
