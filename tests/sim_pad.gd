extends SceneTree
## Menus só com controle: direcional/A na seleção de herói e em "Tentar de novo".

var f := 0
var gs: Node
var fails: Array[String] = []


func _initialize() -> void:
	change_scene_to_file("res://src/ui/character_select.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _btn(index: int, pressed := true) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = index
	ev.pressed = pressed
	Input.parse_input_event(ev)


var _release_at := -1
var _release_idx := 0


func _tap(index: int) -> void:
	_btn(index, true)  # solta 4 quadros depois, como uma pessoa
	_release_at = f + 4
	_release_idx = index


func _focus_name() -> String:
	var o := root.gui_get_focus_owner()
	return o.text if o is Button else "(nada)"


func _process(_d) -> bool:
	f += 1
	if _release_at == f:
		_btn(_release_idx, false)
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_pad_save.json"
	match f:
		15:
			_check(_focus_name() == "Zack", "seleção devia começar focada no herói atual (%s)" % _focus_name())
			_tap(JOY_BUTTON_DPAD_RIGHT)
		25:
			_check(_focus_name() == "Zoe", "direcional direita devia ir para a Zoe (%s)" % _focus_name())
			_tap(JOY_BUTTON_DPAD_LEFT)
		35:
			_check(_focus_name() == "Zack", "direcional esquerda devia voltar (%s)" % _focus_name())
			_tap(JOY_BUTTON_DPAD_LEFT)
		45:
			_check(_focus_name() == "Léo", "esquerda de novo devia ir ao Léo (%s)" % _focus_name())
			_tap(JOY_BUTTON_A)
		70:
			_check(gs.character == "loiro", "A devia escolher o Léo (%s)" % gs.character)
			_check(current_scene != null and current_scene.name.begins_with("Phase"), "devia entrar na fase (%s)" % str(current_scene))
			# morrer e tentar de novo só com o controle
			current_scene.get_node("Player").kill()
		110:
			var over: CanvasLayer = current_scene.get_node("GameOver")
			_check(over.visible and paused, "tela de derrota devia aparecer")
			_check(_focus_name() == "Tentar de novo", "botão devia estar focado (%s)" % _focus_name())
			gs.hp = 3
			_tap(JOY_BUTTON_A)
		160:
			_check(not paused, "A devia despausar e recomeçar")
			_check(gs.hp == gs.max_hp, "recomeço devia encher a vida (hp=%d)" % gs.hp)
			_check(not current_scene.get_node("GameOver").visible, "tela de derrota devia sumir")
			gs.coins = 50
			for c in current_scene.get_children():
				if c.get("shop") != null:
					current_scene.get_node("Player").global_position = c.global_position + Vector3(0, 0.5, 1.8)
					break
		200:
			_check(paused, "loja devia abrir e pausar")
			_check(_focus_name() != "(nada)", "loja devia ter um item focado")
			_tap(JOY_BUTTON_A)
		230:
			_check(gs.coins < 50, "A devia comprar o item focado (coins=%d)" % gs.coins)
			_tap(JOY_BUTTON_B)
		260:
			_check(not paused, "B devia fechar a loja")
			if fails.is_empty():
				print("PAD SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
