extends SceneTree
## Combate novo: soco (60% dano, pouca força), chute (100%, mais força),
## andar mantém a força, parado recupera, correr drena, sem força não bate,
## super soco (correndo + soco), voadora (correndo + pulo + chute) e especial.

var gs: Node
var p: Node
var cyc: Node
var fails: Array[String] = []
var steps: Array = []
var wait := 0
var mem := {}


func _initialize() -> void:
	change_scene_to_file("res://src/levels3d/phase_1.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _add(frames: int, fn: Callable) -> void:
	steps.append([frames, fn])


func _setup() -> void:
	gs = root.get_node("GameState")
	gs.save_path = "user://test_moves_save.json"
	p = current_scene.get_node("Player")
	p.use_test_input = true
	var first := true
	for e in root.get_tree().get_nodes_in_group("enemies"):
		if first:
			cyc = e
			first = false
		else:
			e.queue_free()
	cyc.set_physics_process(false)
	cyc.hp = 9999
	cyc.max_hp = 9999
	_place_cyc()


func _place_cyc() -> void:
	cyc.global_position = p.global_position + Vector3(0, 0.1, -1.3)


func _build() -> void:
	_add(30, func(): _setup())
	_add(20, func():
		mem.hp = cyc.hp
		p.stamina = 100.0
		p.test_pressed["punch"] = true)
	_add(24, func():
		_check(mem.hp - cyc.hp == 2, "soco devia tirar 60%% de 4 = 2 (tirou %d)" % (mem.hp - cyc.hp))
		_check(absf(p.stamina - 92.0) < 1.0, "soco devia gastar 8 de força (%.1f)" % p.stamina)
		_check(p.special > 0.0, "bater devia encher o especial")
		mem.hp = cyc.hp
		p.test_pressed["kick"] = true)
	_add(20, func():
		_check(mem.hp - cyc.hp == 4, "chute devia tirar 4 (tirou %d)" % (mem.hp - cyc.hp))
		_check(absf(p.stamina - 74.0) < 1.5, "chute devia gastar 18 de força (%.1f)" % p.stamina)
		mem.s = p.stamina
		p.test_move = Vector2(0, 1))  # andar: força estável
	_add(40, func():
		_check(absf(p.stamina - mem.s) < 0.6, "andando a força devia ficar estável (%.1f → %.1f)" % [mem.s, p.stamina])
		p.test_move = Vector2.ZERO
		mem.s = p.stamina)
	_add(60, func():
		_check(p.stamina > mem.s + 5.0, "parado a força devia recuperar (%.1f → %.1f)" % [mem.s, p.stamina])
		# correr: velocidade maior e força cai
		p.stamina = 100.0
		mem.pos = p.global_position
		p.test_move = Vector2(1, 0)
		p.test_pressed["run"] = true)
	_add(30, func():
		var d: float = p.global_position.distance_to(mem.pos)
		_check(d > 4.2, "correndo devia andar mais rápido (%.1f m em 0,5 s)" % d)
		_check(p.stamina < 94.0, "correr devia gastar força (%.1f)" % p.stamina)
		# super soco: correndo + soco
		_place_cyc()
		p.facing = Vector3(1, 0, 0)
		mem.hp = cyc.hp
		p.global_position = cyc.global_position + Vector3(-1.2, 0.4, 0)
		p.test_pressed["punch"] = true)
	_add(4, func():
		_check(p._action == "superpunch", "correndo + soco devia dar super soco (ação=%s)" % p._action))
	_add(25, func():
		_check(mem.hp - cyc.hp >= 6, "super soco devia bater forte (tirou %d)" % (mem.hp - cyc.hp))
		# voadora: correndo + pulo + chute no ar
		p.test_pressed["run"] = true
		p.test_move = Vector2(1, 0)
		p.stamina = 100.0
		p.test_pressed["jump"] = true)
	_add(10, func():
		_check(not p.is_on_floor(), "devia estar no ar")
		p.test_pressed["kick"] = true)
	_add(3, func():
		_check(p._action == "flykick", "correndo + pulo + chute devia dar voadora (ação=%s)" % p._action))
	_add(60, func():
		# sem força não bate
		p.test_pressed["run"] = false
		p.test_move = Vector2.ZERO
		p.stamina = 3.0
		_place_cyc()
		mem.hp = cyc.hp
		p.test_pressed["kick"] = true)
	_add(20, func():
		_check(cyc.hp == mem.hp, "sem força o chute não devia sair")
		# especial: precisa da barra cheia; mata os bichos da tela
		var victim: Node = null
		for e in root.get_tree().get_nodes_in_group("enemies"):
			if e != cyc and is_instance_valid(e):
				victim = e
		p.special = 40.0
		p.test_pressed["special"] = true)
	_add(10, func():
		_check(p.special == 40.0, "especial incompleto não devia disparar")
		_check(cyc.hp > 9000, "bicho devia continuar vivo sem o especial")
		var wave: Array = []
		for i in range(3):
			var e: Node3D = load("res://src/enemies3d/cyclops.tscn").instantiate()
			current_scene.add_child(e)
			e.global_position = p.global_position + Vector3(4 + i, 0.1, -3)
			e.set_physics_process(false)
			wave.append(e)
		mem.wave = wave
		p.stamina = 10.0
		p.special = 100.0
		p.test_pressed["special"] = true)
	_add(30, func():
		var dead := 0
		for e in mem.wave:
			if not is_instance_valid(e) or e._dying:
				dead += 1
		_check(dead == 3, "especial devia derrotar todos os bichos da tela (%d/3)" % dead)
		_check(p.special == 0.0, "especial devia zerar a barra")
		_check(p.stamina >= 99.0, "especial devia recarregar a força"))
	_add(5, func():
		if fails.is_empty():
			print("MOVES SIM PASSED")
			quit(0)
		else:
			quit(1))


func _process(_d) -> bool:
	if steps.is_empty() and mem.is_empty() and not mem.has("built"):
		mem["built"] = true
		_build()
	if steps.is_empty():
		return false
	wait += 1
	if wait >= steps[0][0]:
		var fn: Callable = steps[0][1]
		steps.remove_at(0)
		wait = 0
		fn.call()
	return false
