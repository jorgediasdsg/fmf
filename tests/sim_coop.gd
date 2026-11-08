extends SceneTree
## Co-op: 2 jogadores (P1 teclado, P2 controle). P2 anda e ataca por entrada
## simulada; câmera só do P1; controle fora das ações do P1; coleira de 13 m.

var f := 0
var gs: Node
var fails: Array[String] = []
var p1: Node
var p2: Node


func _initialize() -> void:
	pass


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _process(_d) -> bool:
	f += 1
	if f == 1:
		gs = root.get_node("GameState")
		gs.save_path = "user://test_coop_save.json"
		gs.coop = true
		change_scene_to_file("res://src/levels3d/phase_1.tscn")
	match f:
		30:
			var ps := root.get_tree().get_nodes_in_group("player")
			_check(ps.size() == 2, "co-op devia ter 2 jogadores (%d)" % ps.size())
			p1 = current_scene.get_node("Player")
			for p in ps:
				if p.player_id == 2:
					p2 = p
			_check(p2 != null and p2.rig == null, "P2 não devia ter câmera própria")
			_check(p1.rig != null, "P1 devia ter a câmera")
			for ev in InputMap.action_get_events("punch"):
				_check(not (ev is InputEventJoypadButton), "controle devia sair da ação do P1")
			p2.use_test_input = true
			p2.test_move = Vector2(1, 0)
		90:
			_check(p2.global_position.x > p1.global_position.x + 3.0, "P2 devia andar com a entrada dele")
			p2.test_move = Vector2(-1, 0)
		200:
			# nenhum dos dois escapa mais de 13 m do outro
			p2.test_move = Vector2(1, 0)
		400:
			var d: float = p1.global_position.distance_to(p2.global_position)
			_check(d < 14.5, "coleira devia segurar o P2 (dist=%.1f)" % d)
			# P2 ataca um bicho perto dele
			p2.test_move = Vector2.ZERO
			var e: Node3D = root.get_tree().get_nodes_in_group("enemies")[0]
			e.global_position = p2.global_position + Vector3(0, 0.1, 1.0)
			e.set("hp", 99)
			p2.test_pressed["kick"] = true
		440:
			var e2: Node = root.get_tree().get_nodes_in_group("enemies")[0]
			_check(e2.hp < 99 or e2.get("_alert") > 0.0, "ataque do P2 devia acertar o bicho")
			if fails.is_empty():
				print("COOP SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
