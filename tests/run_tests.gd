extends SceneTree
## Executor de testes headless.
## Uso: godot --headless --path . --script tests/run_tests.gd
## Cada arquivo tests/test_*.gd tem métodos test_*() que retornam "" (ok)
## ou uma mensagem de falha.

func _initialize() -> void:
	var failed := 0
	var total := 0
	var dir := DirAccess.open("res://tests")
	if dir == null:
		print("FAIL: pasta tests/ não encontrada")
		quit(1)
		return
	var files := dir.get_files()
	files.sort()
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")):
			continue
		var script: Script = load("res://tests/" + f)
		if script == null:
			print("FAIL %s: script não carregou" % f)
			failed += 1
			total += 1
			continue
		var t: Object = script.new()
		if "scene_tree" in t:
			t.set("scene_tree", self)
		for m in t.get_method_list():
			var n: String = m.name
			if not n.begins_with("test_"):
				continue
			total += 1
			var r: Variant = t.call(n)
			if typeof(r) == TYPE_STRING and r != "":
				failed += 1
				print("FAIL %s.%s: %s" % [f, n, r])
			else:
				print("PASS %s.%s" % [f, n])
		if t is Node:
			t.free()
	if failed == 0:
		print("ALL TESTS PASSED (%d)" % total)
		quit(0)
	else:
		print("%d/%d FAILED" % [failed, total])
		quit(1)
