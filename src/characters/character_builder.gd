class_name CharacterBuilder
extends Object
## Monta os personagens low-poly (estilo blocado, cor chapada + contorno)
## e suas animações procedurais. Todos olham para +Z.
## Cada modelo retorna um Node3D com um AnimationPlayer filho chamado "Anim"
## contendo "idle", "run", "attack" e "die".

const COL := {
	"skin": Color(0.95, 0.8, 0.63),
	"skin_dark": Color(0.85, 0.63, 0.4),
	"hair": Color(0.13, 0.12, 0.16),
	"shirt": Color(0.82, 0.27, 0.28),
	"pants": Color(0.54, 0.37, 0.23),
	"shoes": Color(0.25, 0.23, 0.3),
	"scar": Color(1.0, 0.93, 0.84),
	"blade": Color(0.78, 0.78, 0.84),
	"gold": Color(0.95, 0.8, 0.3),
	"dog_white": Color(0.93, 0.91, 0.86),
	"dog_dark": Color(0.16, 0.15, 0.18),
	"dog_nose": Color(0.1, 0.09, 0.12),
	"cyclops": Color(0.87, 0.62, 0.32),
	"cyclops_boss": Color(0.77, 0.42, 0.28),
	"eye_white": Color(0.97, 0.97, 0.95),
	"pupil": Color(0.15, 0.13, 0.2),
	"mouth": Color(0.55, 0.2, 0.22),
	"horn": Color(0.36, 0.25, 0.16),
}


static func _box(parent: Node3D, size: Vector3, color: Color, pos: Vector3,
		outline := true, name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = ToonMaterial.flat(color)
	if outline:
		ToonMaterial.add_outline(mi, minf(0.025, size.length() * 0.035))
	parent.add_child(mi)
	return mi


static func _pivot(parent: Node3D, name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	parent.add_child(n)
	return n


static func _anim_player(root: Node3D, anims: Dictionary) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	ap.name = "Anim"
	root.add_child(ap)
	var lib := AnimationLibrary.new()
	for anim_name in anims:
		lib.add_animation(anim_name, anims[anim_name])
	ap.add_animation_library("", lib)
	return ap


static func _track(anim: Animation, path: String, keys: Array) -> void:
	## keys: [[tempo, valor], ...]
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, NodePath(path))
	for k in keys:
		anim.track_insert_key(t, k[0], k[1])


static func _humanoid_anims(swing_arms := true) -> Dictionary:
	var idle := Animation.new()
	idle.length = 1.4
	idle.loop_mode = Animation.LOOP_LINEAR
	_track(idle, "Root:position", [[0.0, Vector3.ZERO], [0.7, Vector3(0, 0.035, 0)], [1.4, Vector3.ZERO]])
	_track(idle, "Root/ArmL:rotation", [[0.0, Vector3.ZERO], [0.7, Vector3(0.06, 0, 0.04)], [1.4, Vector3.ZERO]])
	_track(idle, "Root/ArmR:rotation", [[0.0, Vector3.ZERO], [0.7, Vector3(0.06, 0, -0.04)], [1.4, Vector3.ZERO]])

	var run := Animation.new()
	run.length = 0.45
	run.loop_mode = Animation.LOOP_LINEAR
	_track(run, "Root/LegL:rotation", [[0.0, Vector3(0.7, 0, 0)], [0.225, Vector3(-0.7, 0, 0)], [0.45, Vector3(0.7, 0, 0)]])
	_track(run, "Root/LegR:rotation", [[0.0, Vector3(-0.7, 0, 0)], [0.225, Vector3(0.7, 0, 0)], [0.45, Vector3(-0.7, 0, 0)]])
	if swing_arms:
		_track(run, "Root/ArmL:rotation", [[0.0, Vector3(-0.6, 0, 0)], [0.225, Vector3(0.6, 0, 0)], [0.45, Vector3(-0.6, 0, 0)]])
		_track(run, "Root/ArmR:rotation", [[0.0, Vector3(0.6, 0, 0)], [0.225, Vector3(-0.6, 0, 0)], [0.45, Vector3(0.6, 0, 0)]])
	_track(run, "Root:position", [[0.0, Vector3.ZERO], [0.1125, Vector3(0, 0.05, 0)], [0.225, Vector3.ZERO], [0.3375, Vector3(0, 0.05, 0)], [0.45, Vector3.ZERO]])

	var attack := Animation.new()
	attack.length = 0.3
	_track(attack, "Root/ArmR:rotation", [[0.0, Vector3(-2.6, 0, 0)], [0.12, Vector3(0.9, 0, 0)], [0.3, Vector3.ZERO]])
	_track(attack, "Root:rotation", [[0.0, Vector3(0, -0.25, 0)], [0.12, Vector3(0, 0.18, 0)], [0.3, Vector3.ZERO]])

	var die := Animation.new()
	die.length = 0.5
	_track(die, "Root:scale", [[0.0, Vector3.ONE], [0.5, Vector3(1.2, 0.08, 1.2)]])
	_track(die, "Root:position", [[0.0, Vector3.ZERO], [0.5, Vector3(0, -0.3, 0)]])

	return {"idle": idle, "run": run, "attack": attack, "die": die}


static func build_zack() -> Node3D:
	var model := Node3D.new()
	model.name = "ZackModel"
	var root := _pivot(model, "Root", Vector3.ZERO)

	# pernas (pivô no quadril, y=0.5)
	var leg_l := _pivot(root, "LegL", Vector3(-0.14, 0.5, 0))
	_box(leg_l, Vector3(0.2, 0.5, 0.22), COL.pants, Vector3(0, -0.25, 0))
	_box(leg_l, Vector3(0.22, 0.1, 0.26), COL.shoes, Vector3(0, -0.47, 0.02))
	var leg_r := _pivot(root, "LegR", Vector3(0.14, 0.5, 0))
	_box(leg_r, Vector3(0.2, 0.5, 0.22), COL.pants, Vector3(0, -0.25, 0))
	_box(leg_r, Vector3(0.22, 0.1, 0.26), COL.shoes, Vector3(0, -0.47, 0.02))

	# tronco
	_box(root, Vector3(0.52, 0.52, 0.3), COL.shirt, Vector3(0, 0.78, 0))

	# braços (pivô no ombro, y=1.0); manga curta vermelha + antebraço de pele
	var arm_l := _pivot(root, "ArmL", Vector3(-0.33, 1.0, 0))
	_box(arm_l, Vector3(0.16, 0.2, 0.2), COL.shirt, Vector3(0, -0.08, 0))
	_box(arm_l, Vector3(0.14, 0.32, 0.16), COL.skin, Vector3(0, -0.34, 0))
	_box(arm_l, Vector3(0.15, 0.05, 0.17), COL.scar, Vector3(0, -0.26, 0), false, "Scar")
	var arm_r := _pivot(root, "ArmR", Vector3(0.33, 1.0, 0))
	_box(arm_r, Vector3(0.16, 0.2, 0.2), COL.shirt, Vector3(0, -0.08, 0))
	_box(arm_r, Vector3(0.14, 0.32, 0.16), COL.skin, Vector3(0, -0.34, 0))
	# espada na mão direita, lâmina para frente
	var sword := _pivot(arm_r, "Sword", Vector3(0, -0.5, 0.05))
	_box(sword, Vector3(0.05, 0.05, 0.16), COL.horn, Vector3(0, 0, 0.0), false)
	_box(sword, Vector3(0.16, 0.04, 0.05), COL.gold, Vector3(0, 0, 0.1), false)
	_box(sword, Vector3(0.07, 0.025, 0.55), COL.blade, Vector3(0, 0, 0.4))

	# cabeça
	var head := _pivot(root, "Head", Vector3(0, 1.04, 0))
	_box(head, Vector3(0.5, 0.46, 0.44), COL.skin, Vector3(0, 0.25, 0))
	_box(head, Vector3(0.54, 0.18, 0.48), COL.hair, Vector3(0, 0.44, -0.01))
	_box(head, Vector3(0.54, 0.3, 0.1), COL.hair, Vector3(0, 0.33, -0.21))
	# olhos (face +Z)
	_box(head, Vector3(0.07, 0.09, 0.02), COL.pupil, Vector3(-0.11, 0.24, 0.225), false)
	_box(head, Vector3(0.07, 0.09, 0.02), COL.pupil, Vector3(0.11, 0.24, 0.225), false)

	_anim_player(model, _humanoid_anims())
	return model


static func build_dog() -> Node3D:
	var model := Node3D.new()
	model.name = "DogModel"
	var root := _pivot(model, "Root", Vector3.ZERO)

	_box(root, Vector3(0.3, 0.26, 0.55), COL.dog_white, Vector3(0, 0.33, -0.05))
	# patas
	for data in [["LegL", Vector3(-0.1, 0.22, 0.12)], ["LegR", Vector3(0.1, 0.22, 0.12)],
			["LegBL", Vector3(-0.1, 0.22, -0.24)], ["LegBR", Vector3(0.1, 0.22, -0.24)]]:
		var leg := _pivot(root, data[0], data[1])
		_box(leg, Vector3(0.09, 0.22, 0.09), COL.dog_white, Vector3(0, -0.11, 0))
	# cabeça
	var head := _pivot(root, "Head", Vector3(0, 0.44, 0.25))
	_box(head, Vector3(0.3, 0.26, 0.26), COL.dog_white, Vector3(0, 0.08, 0))
	_box(head, Vector3(0.14, 0.12, 0.08), COL.dog_white, Vector3(0, 0.02, 0.16))
	_box(head, Vector3(0.09, 0.07, 0.03), COL.dog_nose, Vector3(0, 0.05, 0.2), false)
	# mancha preta no olho ESQUERDO (lado -X, face +Z) + olhos
	_box(head, Vector3(0.13, 0.13, 0.02), COL.dog_dark, Vector3(-0.08, 0.13, 0.13), false, "Patch")
	_box(head, Vector3(0.05, 0.06, 0.02), COL.eye_white, Vector3(-0.08, 0.13, 0.145), false)
	_box(head, Vector3(0.05, 0.06, 0.015), COL.pupil, Vector3(0.08, 0.13, 0.14), false)
	# orelhas caídas
	_box(head, Vector3(0.08, 0.18, 0.1), COL.dog_dark, Vector3(-0.18, 0.08, -0.02))
	_box(head, Vector3(0.08, 0.18, 0.1), COL.dog_dark, Vector3(0.18, 0.08, -0.02))
	# rabo (pivô para abanar)
	var tail := _pivot(root, "Tail", Vector3(0, 0.42, -0.34))
	_box(tail, Vector3(0.06, 0.06, 0.22), COL.dog_white, Vector3(0, 0.06, -0.1))

	var idle := Animation.new()
	idle.length = 0.8
	idle.loop_mode = Animation.LOOP_LINEAR
	_track(idle, "Root/Tail:rotation", [[0.0, Vector3(0, 0.6, 0)], [0.4, Vector3(0, -0.6, 0)], [0.8, Vector3(0, 0.6, 0)]])
	_track(idle, "Root:position", [[0.0, Vector3.ZERO], [0.4, Vector3(0, 0.02, 0)], [0.8, Vector3.ZERO]])

	var run := Animation.new()
	run.length = 0.3
	run.loop_mode = Animation.LOOP_LINEAR
	for pair in [["LegL", 1.0], ["LegR", -1.0], ["LegBL", -1.0], ["LegBR", 1.0]]:
		_track(run, "Root/%s:rotation" % pair[0],
			[[0.0, Vector3(0.8 * pair[1], 0, 0)], [0.15, Vector3(-0.8 * pair[1], 0, 0)], [0.3, Vector3(0.8 * pair[1], 0, 0)]])
	_track(run, "Root/Tail:rotation", [[0.0, Vector3(0, 0.4, 0)], [0.15, Vector3(0, -0.4, 0)], [0.3, Vector3(0, 0.4, 0)]])

	var attack := Animation.new()
	attack.length = 0.3
	_track(attack, "Root/Head:rotation", [[0.0, Vector3(0.5, 0, 0)], [0.12, Vector3(-0.35, 0, 0)], [0.3, Vector3.ZERO]])
	_track(attack, "Root:rotation", [[0.0, Vector3(-0.15, 0, 0)], [0.3, Vector3.ZERO]])

	var die := Animation.new()
	die.length = 0.5
	_track(die, "Root:scale", [[0.0, Vector3.ONE], [0.5, Vector3(1.1, 0.15, 1.1)]])

	_anim_player(model, {"idle": idle, "run": run, "attack": attack, "die": die})
	return model


static func build_cyclops(body_scale := 1.0, boss := false) -> Node3D:
	var model := Node3D.new()
	model.name = "CyclopsModel"
	var root := _pivot(model, "Root", Vector3.ZERO)
	var col: Color = COL.cyclops_boss if boss else COL.cyclops

	# pernas curtas
	var leg_l := _pivot(root, "LegL", Vector3(-0.22, 0.26, 0))
	_box(leg_l, Vector3(0.2, 0.26, 0.24), COL.horn, Vector3(0, -0.13, 0))
	var leg_r := _pivot(root, "LegR", Vector3(0.22, 0.26, 0))
	_box(leg_r, Vector3(0.2, 0.26, 0.24), COL.horn, Vector3(0, -0.13, 0))

	# corpão (cabeça e corpo juntos)
	_box(root, Vector3(0.9, 0.95, 0.66), col, Vector3(0, 0.76, 0))
	# chifres
	_box(root, Vector3(0.1, 0.22, 0.1), COL.horn, Vector3(-0.3, 1.33, 0))
	_box(root, Vector3(0.1, 0.22, 0.1), COL.horn, Vector3(0.3, 1.33, 0))
	# olho único (face +Z)
	_box(root, Vector3(0.34, 0.3, 0.04), COL.eye_white, Vector3(0, 0.95, 0.33), false)
	_box(root, Vector3(0.13, 0.16, 0.03), COL.pupil, Vector3(0, 0.94, 0.36), false, "Pupil")
	# boca
	_box(root, Vector3(0.3, 0.1, 0.03), COL.mouth, Vector3(0, 0.56, 0.34), false)
	# braços
	var arm_l := _pivot(root, "ArmL", Vector3(-0.5, 1.0, 0))
	_box(arm_l, Vector3(0.16, 0.45, 0.2), col, Vector3(0, -0.2, 0))
	var arm_r := _pivot(root, "ArmR", Vector3(0.5, 1.0, 0))
	_box(arm_r, Vector3(0.16, 0.45, 0.2), col, Vector3(0, -0.2, 0))

	_anim_player(model, _humanoid_anims())
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model
