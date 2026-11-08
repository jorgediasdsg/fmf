extends SceneTree
## Fase 1: comida cura, lojinha abre ao chegar perto (pausa), comprar funciona,
## e a vida enche inteira ao começar a fase.

var f := 0
var gs: Node
var fails: Array[String] = []


func _initialize() -> void:
	change_scene_to_file("res://src/levels3d/phase_1.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _stall_front() -> Vector3:
	for c in current_scene.get_children():
		if c.get("shop") != null:
			return c.global_position + Vector3(0, 0.5, 1.8)
	return Vector3.ZERO


func _process(_d) -> bool:
	f += 1
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_shop_save.json"
	match f:
		10:
			_check(gs.hp == gs.max_hp, "fase nova devia começar com vida cheia")
			gs.hp = 6
			var food: Node = load("res://src/items3d/food.tscn").instantiate()
			food.position = current_scene.get_node("Player").global_position + Vector3(0.2, 0, 0)
			current_scene.add_child(food)
		40:
			_check(gs.hp == 9, "comida devia curar 3 (hp=%d)" % gs.hp)
			gs.coins = 20
			for e in root.get_tree().get_nodes_in_group("enemies"):
				e.queue_free()  # sem contato durante a medição
			# teleporta para o gatilho da lojinha
			current_scene.get_node("Player").global_position = _stall_front()
		70:
			var shop: Node = null
			for c in current_scene.get_children():
				if shop == null and c.get("shop") != null:
					shop = c.shop
			_check(shop != null and shop.visible, "lojinha devia abrir ao chegar perto")
			_check(paused, "jogo devia pausar na lojinha")
			shop._on_buy("apple")
			_check(gs.hp == 12 and gs.coins == 14, "compra de maçã (hp=%d coins=%d)" % [gs.hp, gs.coins])
			shop.close()
			_check(not paused, "fechar a lojinha devia despausar")
		110:
			if fails.is_empty():
				print("SHOP SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
