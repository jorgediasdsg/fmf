extends SceneTree
## Moita (SCENE=...): escondido, nenhum bicho persegue/atira/machuca; fora da
## moita o bicho visível machuca o herói.

var f := 0
var gs: Node
var fails: Array[String] = []
var enemy: Node
var player: Node
var bush: Node3D
var hp_b := 0
var saw_ink := false


func _initialize() -> void:
	var sp := OS.get_environment("SCENE")
	change_scene_to_file(sp if sp != "" else "res://src/levels3d/phase_1.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


## Ponto fora de qualquer moita (e das paredes) perto da primeira moita.
func _open_spot() -> Vector3:
	var bushes: Array = current_scene.get_children().filter(func(c): return c.get("greens") != null)
	for off in [Vector3(7, 0, 0), Vector3(-7, 0, 0), Vector3(0, 0, 7), Vector3(0, 0, -7), Vector3(10, 0, 4), Vector3(-10, 0, 4)]:
		var cand: Vector3 = bush.global_position + off
		var ok := absf(cand.x) < 45.0 and absf(cand.z) < 35.0
		for b in bushes:
			if b.global_position.distance_to(cand) < 3.5:
				ok = false
		if ok and not current_scene._near_wall(cand, 3.5):
			return cand
	return bush.global_position + Vector3(7, 0, 0)


func _process(_d) -> bool:
	f += 1
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_hide_save.json"
	if f > 220:
		for c in current_scene.get_children():
			if c is Area3D and c.get("direction") != null:
				saw_ink = true
	match f:
		10:
			player = current_scene.get_node("Player")
			for c in current_scene.get_children():
				if bush == null and c.get("greens") != null:
					bush = c
			_check(bush != null, "devia existir moita")
			var keep := false
			for e in root.get_tree().get_nodes_in_group("enemies"):
				if not keep:
					enemy = e
					keep = true
				else:
					e.queue_free()
			player.global_position = bush.global_position + Vector3(0, 0.5, 0)
			enemy.global_position = bush.global_position + Vector3(0, 0.1, 5.0)
		40:
			_check(player.is_hidden(), "herói na moita devia estar escondido")
		200:
			_check(gs.hp == gs.max_hp, "escondido não devia levar dano (hp=%d)" % gs.hp)
			var spot := _open_spot()
			player.global_position = spot + Vector3(0, 0.5, 0)
			enemy.global_position = spot + Vector3(0, 0.1, -3.0)
			hp_b = gs.hp
		220:
			_check(not player.is_hidden(), "fora da moita não devia estar escondido")
		420:
			_check(gs.hp < hp_b or saw_ink, "bicho devia atacar o herói visível (hp=%d)" % gs.hp)
			if fails.is_empty():
				print("HIDE SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
