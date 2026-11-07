extends SceneTree
## Fase 1: 3 portões; limpar a clareira 1 abre o 1º portão; cair mata e
## o retry recarrega com vida cheia; matar o chefe dá vitória e salva a fase.

var f := 0
var gs: Node
var fails: Array[String] = []
var xp_b := 0
var lvl_b := 0
var coins_b := 0


func _initialize() -> void:
	change_scene_to_file("res://src/levels3d/phase_1.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _gates() -> int:
	return root.get_tree().get_nodes_in_group("gate").filter(is_instance_valid).size()


func _process(_d) -> bool:
	f += 1
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_phase_save.json"
	match f:
		20:
			var sfx := root.get_node_or_null("Sfx")
			_check(sfx != null and sfx.process_mode == Node.PROCESS_MODE_ALWAYS,
				"Sfx devia tocar mesmo pausado (PROCESS_MODE_ALWAYS)")
			_check(_gates() == 3, "deviam existir 3 portões, há %d" % _gates())
			var zone1 := 0
			for e in root.get_tree().get_nodes_in_group("enemies"):
				if e.global_position.x < 20.0:
					zone1 += 1
					e.take_hit(999, Vector3.ZERO)
			_check(zone1 == 2, "clareira 1 devia ter 2 ciclopes, tinha %d" % zone1)
		140:
			_check(_gates() == 2, "portão 1 devia ter aberto (%d restantes)" % _gates())
			Input.action_press("move_right")  # dedo no joystick na hora da morte
			current_scene.get_node("Player").global_position = Vector3(5, -12, 0)
		200:
			var over: CanvasLayer = current_scene.get_node("GameOver")
			_check(over.visible, "tela de derrota devia aparecer após a queda")
			_check(paused, "o jogo devia pausar na derrota")
			over.action.emit()
		280:
			_check(gs.hp == gs.max_hp, "retry devia encher a vida (hp=%d)" % gs.hp)
			_check(_gates() == 3, "fase recarregada devia ter 3 portões (%d)" % _gates())
			_check(not Input.is_action_pressed("move_right"),
				"retry devia soltar o joystick (move_right ainda pressionado)")
			xp_b = gs.xp
			lvl_b = gs.level
			coins_b = gs.coins
			for e in root.get_tree().get_nodes_in_group("enemies"):
				if e.get("boss"):
					e.take_hit(999, Vector3.ZERO)
		340:
			_check(current_scene.get_node("Victory").visible, "tela de vitória devia aparecer")
			_check(gs.phases_done.has(1), "fase 1 devia estar salva como concluída")
			_check(gs.xp != xp_b or gs.level != lvl_b,
				"XP do chefe devia ser creditado (xp %d nv %d inalterados)" % [gs.xp, gs.level])
			_check(gs.coins >= coins_b + 8, "moedas do chefe deviam ser creditadas (%d → %d)" % [coins_b, gs.coins])
			var fsave := FileAccess.open("user://test_phase_save.json", FileAccess.READ)
			if fsave == null:
				_check(false, "save da vitória devia existir")
			else:
				var data: Variant = JSON.parse_string(fsave.get_as_text())
				fsave.close()
				_check(typeof(data) == TYPE_DICTIONARY
					and int(data.get("xp", -1)) == gs.xp
					and int(data.get("level", -1)) == gs.level
					and int(data.get("coins", -1)) == gs.coins,
					"save da vitória devia conter XP/nível/moedas do chefe (arquivo=%s vs gs xp=%d nv=%d c=%d)"
						% [str(data), gs.xp, gs.level, gs.coins])
			if fails.is_empty():
				print("PHASE1 SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
