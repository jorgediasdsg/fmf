extends SceneTree
## Fase 5: o Gorila Rei joga 2 árvores a cada 5 s; cada uma tira metade da vida
## (8 de 15); dá para escapar saindo da linha; o chefe tem muita vida.

var f := 0
var gs: Node
var fails: Array[String] = []
var boss: Node
var p: Node


func _initialize() -> void:
	change_scene_to_file("res://src/levels3d/phase_5.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _trees() -> Array:
	return root.get_tree().get_nodes_in_group("tree_missile").filter(func(e): return is_instance_valid(e))


func _process(_d) -> bool:
	f += 1
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_gorilla_save.json"
	match f:
		20:
			for c in current_scene.get_children():
				if c.get("greens") != null:
					c.queue_free()  # sem moitas (o herói escondido não é alvo)
			for e in root.get_tree().get_nodes_in_group("enemies"):
				for i in range(40):
					if is_instance_valid(e):
						e.take_hit(9999, Vector3.ZERO)
		200:
			var bs := root.get_tree().get_nodes_in_group("boss")
			_check(bs.size() == 1, "Gorila Rei devia aparecer")
			boss = bs[0]
			_check(boss.max_hp >= 150, "gorila chefe devia ter muita vida (%d)" % boss.max_hp)
			p = current_scene.get_node("Player")
			p.use_test_input = true
			p._bushes = 0
			boss.global_position = Vector3(0, 0.1, -20)
			p.global_position = Vector3(0, 0.5, -10)
			boss._throw_t = 0.2  # logo
		215:
			_check(_trees().size() == 2, "chefe devia arremessar 2 árvores (%d)" % _trees().size())
			var d0: Vector3 = _trees()[0].direction
			var d1: Vector3 = _trees()[1].direction
			_check(d0.distance_to(d1) > 0.2, "as árvores devem ir em direções diferentes")
			p.test_move = Vector2.ZERO
		260:
			_check(gs.hp <= gs.max_hp - 8, "árvore devia tirar metade da vida (hp=%d)" % gs.hp)
			gs.hp = gs.max_hp
			p._iframes = 0.0
			boss._throw_t = 0.2
			boss.global_position = Vector3(0, 0.1, -20)
			p.global_position = Vector3(0, 0.5, -10)
			p.test_move = Vector2(1, 0)   # desvia de lado
		330:
			_check(gs.hp == gs.max_hp, "desviando de lado não devia levar árvore (hp=%d)" % gs.hp)
			if fails.is_empty():
				print("GORILLA SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
