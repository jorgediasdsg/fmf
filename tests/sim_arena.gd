extends SceneTree
## Arena (SCENE=res://src/levels3d/phase_N.tscn): chefe só aparece depois de
## derrotar TODOS os bichos; bichos se ajudam; cair mata e o retry recarrega
## tudo; derrotar o chefe dá vitória e salva a fase.

var f := 0
var gs: Node
var fails: Array[String] = []
var total := 0
var scene_path := ""
var xp_b := 0
var coins_b := 0


func _initialize() -> void:
	scene_path = OS.get_environment("SCENE")
	if scene_path == "":
		scene_path = "res://src/levels3d/phase_1.tscn"
	change_scene_to_file(scene_path)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _enemies() -> Array:
	return root.get_tree().get_nodes_in_group("enemies").filter(func(e): return is_instance_valid(e) and not e.get("_dying"))


func _bosses() -> Array:
	return root.get_tree().get_nodes_in_group("boss").filter(func(e): return is_instance_valid(e))


func _kill_all_small() -> void:
	for e in root.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.get("boss"):
			for i in range(10):  # acertos fixos (aliens) precisam de vários golpes
				if is_instance_valid(e):
					e.take_hit(999, Vector3.ZERO)


func _process(_d) -> bool:
	f += 1
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_arena_save.json"
	match f:
		20:
			total = _enemies().size()
			_check(total >= 20, "devia haver 20+ bichos no mapa, há %d" % total)
			_check(_bosses().is_empty(), "o chefe não devia existir no começo")
			_check(root.get_tree().get_nodes_in_group("gate").is_empty(), "não há mais portões")
			# ajuda mútua: acertar um bicho alerta os vizinhos
			var a: Node3D = _enemies()[0]
			var neighbors := _enemies().filter(func(e): return e != a and e.global_position.distance_to(a.global_position) < 12.0)
			_check(neighbors.size() >= 1, "o grupo devia ter vizinhos")
			a.take_hit(1, Vector3.ZERO)
			var alerted := neighbors.filter(func(e): return e.get("_alert") > 0.0)
			_check(alerted.size() == neighbors.size(), "vizinhos deviam ser alertados (%d/%d)" % [alerted.size(), neighbors.size()])
		40:
			_kill_all_small()
		60:
			_check(_bosses().is_empty(), "chefe não devia aparecer antes do fim do atraso")
		160:
			_check(_bosses().size() == 1, "chefe devia aparecer após derrotar todos (%d)" % _bosses().size())
			Input.action_press("move_right")
			current_scene.get_node("Player").global_position = Vector3(5, -12, 0)  # cai
		220:
			var over: CanvasLayer = current_scene.get_node("GameOver")
			_check(over.visible and paused, "tela de derrota devia aparecer e pausar")
			over.action.emit()
		300:
			_check(gs.hp == gs.max_hp, "retry devia encher a vida")
			_check(not Input.is_action_pressed("move_right"), "retry devia soltar o joystick")
			_check(_enemies().size() == total, "retry devia recriar os %d bichos (há %d)" % [total, _enemies().size()])
			_check(_bosses().is_empty(), "após o retry o chefe some de novo")
			xp_b = gs.xp + gs.level * 1000
			coins_b = gs.coins
			_kill_all_small()
		440:
			_check(_bosses().size() == 1, "chefe devia reaparecer")
			for b in _bosses():
				for i in range(10):
					if is_instance_valid(b):
						b.take_hit(9999, Vector3.ZERO)
		520:
			_check(current_scene.get_node("Victory").visible, "vitória devia aparecer")
			_check(gs.phases_done.has(current_scene.phase_index), "fase devia estar salva")
			_check(gs.xp + gs.level * 1000 != xp_b, "XP devia ser creditado")
			_check(gs.coins > coins_b, "moedas deviam ser creditadas")
			if fails.is_empty():
				print("ARENA SIM PASSED (%s)" % scene_path.get_file())
				quit(0)
			else:
				quit(1)
	return false
