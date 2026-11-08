extends SceneTree
## Fase 4: saucer morre com 3 golpes; chefe com 7; chefe joga ovo a cada 5 s;
## ovo choca 5 mini aliens que dão pouco dano (1) e morrem com 2 golpes.

var f := 0
var gs: Node
var fails: Array[String] = []
var boss: Node
var saucer: Node
var mini: Node


func _initialize() -> void:
	change_scene_to_file("res://src/levels3d/phase_4.tscn")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL: " + msg)


func _group(n: String) -> Array:
	return root.get_tree().get_nodes_in_group(n).filter(func(e): return is_instance_valid(e))


func _process(_d) -> bool:
	f += 1
	if gs == null and root.has_node("GameState"):
		gs = root.get_node("GameState")
		gs.save_path = "user://test_alien_save.json"
	match f:
		20:
			saucer = _group("enemies")[0]
			saucer.take_hit(999, Vector3.ZERO)
			saucer.take_hit(999, Vector3.ZERO)
			_check(saucer.hp == 1, "nave devia estar com 1 golpe restante (hp=%d)" % saucer.hp)
			saucer.take_hit(999, Vector3.ZERO)
			_check(saucer.hp <= 0, "nave devia morrer no 3º golpe")
		40:
			for e in _group("enemies"):
				for i in range(5):
					if is_instance_valid(e):
						e.take_hit(999, Vector3.ZERO)
		180:
			var bs := _group("boss")
			_check(bs.size() == 1, "Alien Pai devia aparecer")
			if bs.size() == 1:
				boss = bs[0]
				boss.global_position = Vector3(0, 0.1, -20)
				current_scene.get_node("Player").global_position = Vector3(0, 0.5, -30)
		200:
			_check(boss.max_hp == 7, "chefe devia ter 7 golpes (max_hp=%d)" % boss.max_hp)
		560:  # >5 s depois: pelo menos um ovo já foi lançado
			_check(_group("egg").size() + _group("mini").size() > 0, "chefe devia ter jogado um ovo")
		700:
			var minis := _group("mini")
			_check(minis.size() >= 5, "ovo devia chocar 5 mini aliens (há %d)" % minis.size())
			if minis.size() > 0:
				mini = minis[0]
				_check(mini.contact_damage == 1, "mini alien devia dar pouco dano (%d)" % mini.contact_damage)
				mini.take_hit(999, Vector3.ZERO)
				_check(mini.hp == 1, "mini devia sobreviver ao 1º golpe (hp=%d)" % mini.hp)
				mini.take_hit(999, Vector3.ZERO)
				_check(mini.hp <= 0, "mini devia morrer no 2º golpe")
			for i in range(6):
				boss.take_hit(999, Vector3.ZERO)
			_check(boss.hp == 1 and not current_scene.get_node("Victory").visible, "chefe devia ter sobrado 1 golpe (hp=%d)" % boss.hp)
			boss.take_hit(999, Vector3.ZERO)
		780:
			_check(current_scene.get_node("Victory").visible, "vitória devia aparecer ao derrotar o chefe")
			_check(gs.phases_done.has(4), "fase 4 devia ser salva")
			if fails.is_empty():
				print("ALIEN SIM PASSED")
				quit(0)
			else:
				quit(1)
	return false
