class_name CharacterBuilder
extends Object
## Monta os personagens low-poly (estilo blocado, cor chapada + contorno)
## e suas animações procedurais. Todos olham para +Z.
## Cada modelo retorna um Node3D com um AnimationPlayer filho chamado "Anim"
## contendo "idle", "run", "attack" e "die".

const COL := {
	"skin": Color(1.0, 0.8, 0.6),
	"skin_dark": Color(0.85, 0.63, 0.4),
	"hair": Color(0.13, 0.12, 0.16),
	"shirt": Color(0.86, 0.12, 0.14),
	"pants": Color(0.09, 0.09, 0.11),
	"shoes": Color(0.94, 0.94, 0.96),
	"scar": Color(1.0, 0.93, 0.84),
	"blade": Color(0.78, 0.78, 0.84),
	"gold": Color(0.95, 0.8, 0.3),
	"dog_white": Color(0.93, 0.91, 0.86),
	"dog_dark": Color(0.16, 0.15, 0.18),
	"dog_nose": Color(0.1, 0.09, 0.12),
	"cyclops": Color(0.95, 0.66, 0.25),
	"cyclops_boss": Color(0.9, 0.42, 0.25),
	"octopus": Color(0.98, 0.45, 0.62),
	"octopus_boss": Color(0.62, 0.38, 0.92),
	"cheek": Color(1.0, 0.55, 0.6),
	"yeti": Color(0.97, 0.98, 1.0),
	"yeti_boss": Color(0.7, 0.86, 1.0),
	"yeti_face": Color(0.6, 0.8, 0.95),
	"ice": Color(0.55, 0.85, 1.0),
	"gorilla": Color(0.36, 0.31, 0.33),
	"gorilla_boss": Color(0.5, 0.53, 0.6),
	"gorilla_face": Color(0.78, 0.6, 0.48),
	"alien": Color(0.45, 0.88, 0.4),
	"alien_dad": Color(0.32, 0.72, 0.5),
	"alien_mini": Color(0.65, 0.96, 0.45),
	"saucer": Color(0.78, 0.8, 0.9),
	"glass": Color(0.55, 0.9, 1.0),
	"egg": Color(0.97, 0.94, 0.84),
	"eye_white": Color(0.97, 0.97, 0.95),
	"pupil": Color(0.15, 0.13, 0.2),
	"mouth": Color(0.55, 0.2, 0.22),
	"horn": Color(0.36, 0.25, 0.16),
}


## Heróis jogáveis. Mesma silhueta chibi, roupa e cabelo diferentes.
const LOOKS := {
	"loiro": {"shirt": Color(0.2, 0.45, 0.92), "pants": Color(0.22, 0.26, 0.4),
		"shoes": Color(0.94, 0.94, 0.96), "hair": Color(0.99, 0.82, 0.28),
		"long_hair": false, "skirt": false, "scar": false, "cap": false, "face": "friendly"},
	"zack": {"shirt": Color(0.86, 0.12, 0.14), "pants": Color(0.09, 0.09, 0.11),
		"shoes": Color(0.94, 0.94, 0.96), "hair": Color(0.13, 0.12, 0.16),
		"long_hair": false, "skirt": false, "scar": true, "cap": true, "face": "cool"},
	"menina": {"shirt": Color(0.16, 0.7, 0.3), "pants": Color(0.1, 0.55, 0.24),
		"shoes": Color(0.12, 0.55, 0.25), "hair": Color(0.6, 0.32, 0.88),
		"long_hair": true, "skirt": true, "scar": false, "cap": false, "face": "happy"},
}
const HERO_ORDER := ["loiro", "zack", "menina"]
const HERO_NAMES := {"loiro": "Léo", "zack": "Zack", "menina": "Zoe"}

const OUTLINE := 0.03

static var _mesh_cache: Dictionary = {}
static var low_detail := false  # celular fraco: malhas redondas com menos faces


static func _unit_mesh(kind: String) -> Mesh:
	## Meshes unitários compartilhados (poucos polígonos: web e celular fraco).
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var m: Mesh
	if kind == "sphere":
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 10 if low_detail else 16
		sm.rings = 5 if low_detail else 8
		m = sm
	else:  # cápsula de 1 x 1.6 x 1 (eixo Y)
		var cm := CapsuleMesh.new()
		cm.radius = 0.5
		cm.height = 1.6
		cm.radial_segments = 8 if low_detail else 14
		cm.rings = 2 if low_detail else 4
		m = cm
	_mesh_cache[kind] = m
	return m


static func _shape(kind: String, parent: Node3D, size: Vector3, color: Color, pos: Vector3,
		outline: bool, name: String, rot_deg: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	mi.mesh = _unit_mesh(kind)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = size if kind == "sphere" else Vector3(size.x, size.y / 1.6, size.z)
	mi.material_override = ToonMaterial.flat(color)
	if outline:
		var avg := (mi.scale.x + mi.scale.y + mi.scale.z) / 3.0
		ToonMaterial.add_outline(mi, OUTLINE / maxf(avg, 0.05))
	parent.add_child(mi)
	return mi


## Elipsoide arredondado. size = diâmetros (x, y, z).
static func blob(parent: Node3D, size: Vector3, color: Color, pos: Vector3,
		outline := true, name := "", rot_deg := Vector3.ZERO) -> MeshInstance3D:
	return _shape("sphere", parent, size, color, pos, outline, name, rot_deg)


## Cápsula (membros, troncos). size = (largura, comprimento no eixo Y, profundidade).
static func cap(parent: Node3D, size: Vector3, color: Color, pos: Vector3,
		outline := true, name := "", rot_deg := Vector3.ZERO) -> MeshInstance3D:
	return _shape("capsule", parent, size, color, pos, outline, name, rot_deg)


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


static func _humanoid_anims(swing_arms := true, kick := false) -> Dictionary:
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
	if kick:
		# chute: recua a perna direita e estica para frente
		_track(attack, "Root/LegR:rotation", [[0.0, Vector3(0.7, 0, 0)], [0.1, Vector3(-1.5, 0, 0)], [0.3, Vector3.ZERO]])
		_track(attack, "Root/ArmL:rotation", [[0.0, Vector3(-0.8, 0, 0)], [0.3, Vector3.ZERO]])
		_track(attack, "Root/ArmR:rotation", [[0.0, Vector3(0.8, 0, 0)], [0.3, Vector3.ZERO]])
		_track(attack, "Root:rotation", [[0.0, Vector3(0.12, 0, 0)], [0.1, Vector3(-0.12, 0, 0)], [0.3, Vector3.ZERO]])
	else:
		_track(attack, "Root/ArmR:rotation", [[0.0, Vector3(-2.6, 0, 0)], [0.12, Vector3(0.9, 0, 0)], [0.3, Vector3.ZERO]])
		_track(attack, "Root:rotation", [[0.0, Vector3(0, -0.25, 0)], [0.12, Vector3(0, 0.18, 0)], [0.3, Vector3.ZERO]])

	var die := Animation.new()
	die.length = 0.5
	_track(die, "Root:scale", [[0.0, Vector3.ONE], [0.5, Vector3(1.2, 0.08, 1.2)]])
	_track(die, "Root:position", [[0.0, Vector3.ZERO], [0.5, Vector3(0, -0.3, 0)]])

	var anims := {"idle": idle, "run": run, "attack": attack, "die": die}
	if kick:
		# soco: braço direito dispara para frente (curto e rápido)
		var punch := Animation.new()
		punch.length = 0.25
		_track(punch, "Root/ArmR:rotation", [[0.0, Vector3(-0.6, 0, 0)], [0.07, Vector3(-1.55, 0, 0)], [0.25, Vector3.ZERO]])
		_track(punch, "Root/ArmL:rotation", [[0.0, Vector3(0.5, 0, 0)], [0.25, Vector3.ZERO]])
		_track(punch, "Root:rotation", [[0.0, Vector3(0, 0.2, 0)], [0.07, Vector3(0, -0.2, 0)], [0.25, Vector3.ZERO]])
		anims["punch"] = punch
		# super soco: investida com os dois braços e o corpo inclinado
		var sp := Animation.new()
		sp.length = 0.3
		_track(sp, "Root/ArmR:rotation", [[0.0, Vector3(-1.6, 0, 0)], [0.3, Vector3(-1.6, 0, 0)]])
		_track(sp, "Root/ArmL:rotation", [[0.0, Vector3(-1.2, 0, 0.4)], [0.3, Vector3(-1.2, 0, 0.4)]])
		_track(sp, "Root:rotation", [[0.0, Vector3(0.45, 0, 0)], [0.3, Vector3(0.45, 0, 0)]])
		_track(sp, "Root/LegL:rotation", [[0.0, Vector3(0.9, 0, 0)], [0.3, Vector3(0.9, 0, 0)]])
		_track(sp, "Root/LegR:rotation", [[0.0, Vector3(-0.9, 0, 0)], [0.3, Vector3(-0.9, 0, 0)]])
		anims["superpunch"] = sp
		# voadora: corpo deitado para frente, perna da frente esticada
		var fk := Animation.new()
		fk.length = 0.5
		_track(fk, "Root:rotation", [[0.0, Vector3(-0.9, 0, 0)], [0.5, Vector3(-0.9, 0, 0)]])
		_track(fk, "Root/LegR:rotation", [[0.0, Vector3(-1.4, 0, 0)], [0.5, Vector3(-1.4, 0, 0)]])
		_track(fk, "Root/LegL:rotation", [[0.0, Vector3(0.7, 0, 0)], [0.5, Vector3(0.7, 0, 0)]])
		_track(fk, "Root/ArmL:rotation", [[0.0, Vector3(-2.4, 0, 0.5)], [0.5, Vector3(-2.4, 0, 0.5)]])
		_track(fk, "Root/ArmR:rotation", [[0.0, Vector3(-2.4, 0, -0.5)], [0.5, Vector3(-2.4, 0, -0.5)]])
		anims["flykick"] = fk
		# pulo: braços para cima, pernas dobradas
		var jp := Animation.new()
		jp.length = 0.4
		jp.loop_mode = Animation.LOOP_LINEAR
		_track(jp, "Root/ArmL:rotation", [[0.0, Vector3(-2.6, 0, 0.3)], [0.4, Vector3(-2.6, 0, 0.3)]])
		_track(jp, "Root/ArmR:rotation", [[0.0, Vector3(-2.6, 0, -0.3)], [0.4, Vector3(-2.6, 0, -0.3)]])
		_track(jp, "Root/LegL:rotation", [[0.0, Vector3(0.5, 0, 0)], [0.4, Vector3(0.5, 0, 0)]])
		_track(jp, "Root/LegR:rotation", [[0.0, Vector3(-0.3, 0, 0)], [0.4, Vector3(-0.3, 0, 0)]])
		anims["jump"] = jp
	return anims


static func build_zack() -> Node3D:
	return build_hero("zack")


static func build_hero(id: String) -> Node3D:
	## Estilo Brawl Stars: cabeça enorme, corpo pequeno, mãos e tênis gordinhos.
	var look: Dictionary = LOOKS.get(id, LOOKS["zack"])
	var shirt: Color = look.shirt
	var pants: Color = look.pants
	var hair: Color = look.hair
	var model := Node3D.new()
	model.name = "ZackModel"
	var root := _pivot(model, "Root", Vector3.ZERO)

	var leg_color: Color = COL.skin if look.skirt else pants
	for data in [["LegL", -0.13], ["LegR", 0.13]]:
		var leg := _pivot(root, data[0], Vector3(data[1], 0.4, 0))
		cap(leg, Vector3(0.21, 0.42, 0.21), leg_color, Vector3(0, -0.18, 0))
		blob(leg, Vector3(0.27, 0.19, 0.4), look.shoes, Vector3(0, -0.31, 0.06))

	cap(root, Vector3(0.5, 0.52, 0.36), shirt, Vector3(0, 0.66, 0))
	if look.skirt:  # saia rodada
		blob(root, Vector3(0.7, 0.34, 0.56), pants, Vector3(0, 0.44, 0))

	for data in [["ArmL", -0.34], ["ArmR", 0.34]]:
		var arm := _pivot(root, data[0], Vector3(data[1], 0.84, 0))
		cap(arm, Vector3(0.2, 0.26, 0.2), shirt, Vector3(0, -0.07, 0))
		cap(arm, Vector3(0.15, 0.3, 0.15), COL.skin, Vector3(0, -0.26, 0))
		blob(arm, Vector3(0.18, 0.18, 0.18), COL.skin, Vector3(0, -0.42, 0))
		if data[0] == "ArmL" and look.scar:  # cicatriz: lembrança da família
			blob(arm, Vector3(0.17, 0.05, 0.17), COL.scar, Vector3(0, -0.2, 0), false, "Scar")

	var head := _pivot(root, "Head", Vector3(0, 0.88, 0))
	blob(head, Vector3(0.84, 0.76, 0.76), COL.skin, Vector3(0, 0.36, 0))
	_hair_and_hat(head, look, hair)
	_face(head, look.face)

	_anim_player(model, _humanoid_anims(true, true))
	return model


static func _hair_and_hat(head: Node3D, look: Dictionary, hair: Color) -> void:
	if look.cap:
		# boné de viseira: cabelo só aparece atrás e nas laterais
		blob(head, Vector3(0.84, 0.36, 0.52), hair, Vector3(0, 0.38, -0.2))
		var cap_color := Color(0.1, 0.1, 0.13)
		blob(head, Vector3(0.9, 0.46, 0.84), cap_color, Vector3(0, 0.6, -0.02))
		blob(head, Vector3(0.64, 0.08, 0.46), cap_color, Vector3(0, 0.55, 0.42), true, "", Vector3(-12, 0, 0))
		blob(head, Vector3(0.12, 0.1, 0.12), look.shirt, Vector3(0, 0.84, -0.02))
		return
	blob(head, Vector3(0.86, 0.5, 0.78), hair, Vector3(0, 0.55, -0.05))
	if look.long_hair:
		# cabelo comprido e ondulado: cortina atrás, mechas dos lados, franja de lado
		blob(head, Vector3(0.9, 1.0, 0.44), hair, Vector3(0, 0.08, -0.24))
		blob(head, Vector3(0.56, 0.34, 0.5), hair, Vector3(-0.05, 0.76, 0.02))
		for x in [-0.42, 0.42]:
			cap(head, Vector3(0.18, 0.66, 0.24), hair, Vector3(x, 0.18, 0.0))
			blob(head, Vector3(0.24, 0.24, 0.24), hair, Vector3(x * 1.05, -0.16, -0.02))
		blob(head, Vector3(0.6, 0.22, 0.32), hair, Vector3(0.14, 0.63, 0.22), true, "", Vector3(0, 0, -14))
	else:
		blob(head, Vector3(0.3, 0.14, 0.2), hair, Vector3(0.1, 0.68, 0.22))  # tufo na frente


## Rosto estilo Brawl Stars: olhão com branco, sobrancelha grossa, nariz.
static func _face(head: Node3D, style: String) -> void:
	var tilt := -14.0  # sobrancelhas "decididas" (ponta de dentro mais baixa)
	if style == "happy":
		tilt = 9.0
	elif style == "friendly":
		tilt = 3.0
	for side in [-1.0, 1.0]:
		var x: float = 0.17 * side
		blob(head, Vector3(0.2, 0.23, 0.06), COL.eye_white, Vector3(x, 0.34, 0.335), false)
		var pupil := Vector3(0.1, 0.15, 0.05)
		if style == "happy":
			pupil = Vector3(0.12, 0.17, 0.05)
		blob(head, pupil, COL.pupil, Vector3(x + 0.015 * side, 0.335, 0.365), false)
		blob(head, Vector3(0.04, 0.05, 0.03), COL.eye_white, Vector3(x + 0.04 * side, 0.375, 0.385), false)
		cap(head, Vector3(0.075, 0.24, 0.06), COL.hair if style != "happy" else Color(0.35, 0.18, 0.55),
			Vector3(x, 0.52, 0.32), false, "", Vector3(0, 0, 90 + tilt * -side))
		blob(head, Vector3(0.13, 0.07, 0.04), COL.cheek, Vector3(x * 1.75, 0.2, 0.3), false)
	blob(head, Vector3(0.07, 0.06, 0.06), COL.skin_dark, Vector3(0, 0.26, 0.375), false)  # nariz
	match style:
		"happy":  # sorrisão de boca aberta
			blob(head, Vector3(0.3, 0.17, 0.06), COL.mouth, Vector3(0, 0.14, 0.355), false)
			blob(head, Vector3(0.24, 0.05, 0.04), COL.eye_white, Vector3(0, 0.19, 0.385), false)
			blob(head, Vector3(0.14, 0.07, 0.04), COL.cheek, Vector3(0, 0.1, 0.385), false)
		"cool":  # sorrisinho de lado
			blob(head, Vector3(0.18, 0.06, 0.05), COL.mouth, Vector3(0.04, 0.15, 0.36), false, "", Vector3(0, 0, 8))
		_:
			blob(head, Vector3(0.2, 0.09, 0.05), COL.mouth, Vector3(0, 0.15, 0.36), false)


static func build_dog() -> Node3D:
	var model := Node3D.new()
	model.name = "DogModel"
	var root := _pivot(model, "Root", Vector3.ZERO)

	blob(root, Vector3(0.44, 0.4, 0.72), COL.dog_white, Vector3(0, 0.36, -0.05))
	for data in [["LegL", Vector3(-0.12, 0.2, 0.15)], ["LegR", Vector3(0.12, 0.2, 0.15)],
			["LegBL", Vector3(-0.12, 0.2, -0.25)], ["LegBR", Vector3(0.12, 0.2, -0.25)]]:
		var leg := _pivot(root, data[0], data[1])
		cap(leg, Vector3(0.13, 0.24, 0.13), COL.dog_white, Vector3(0, -0.1, 0))
	var head := _pivot(root, "Head", Vector3(0, 0.48, 0.3))
	blob(head, Vector3(0.5, 0.44, 0.44), COL.dog_white, Vector3(0, 0.12, 0))
	blob(head, Vector3(0.24, 0.18, 0.2), COL.dog_white, Vector3(0, 0.05, 0.22))
	blob(head, Vector3(0.1, 0.08, 0.07), COL.dog_nose, Vector3(0, 0.1, 0.33), false)
	# mancha preta no olho ESQUERDO (lado -X, face +Z) + olhos
	blob(head, Vector3(0.2, 0.2, 0.08), COL.dog_dark, Vector3(-0.11, 0.2, 0.19), false, "Patch")
	blob(head, Vector3(0.08, 0.1, 0.04), COL.eye_white, Vector3(-0.11, 0.2, 0.225), false)
	blob(head, Vector3(0.08, 0.1, 0.04), COL.pupil, Vector3(0.11, 0.2, 0.2), false)
	# orelhas caídas
	cap(head, Vector3(0.13, 0.28, 0.16), COL.dog_dark, Vector3(-0.26, 0.12, -0.02), true, "", Vector3(0, 0, 15))
	cap(head, Vector3(0.13, 0.28, 0.16), COL.dog_dark, Vector3(0.26, 0.12, -0.02), true, "", Vector3(0, 0, -15))
	var tail := _pivot(root, "Tail", Vector3(0, 0.42, -0.4))
	cap(tail, Vector3(0.09, 0.28, 0.09), COL.dog_white, Vector3(0, 0.05, -0.1), true, "", Vector3(-70, 0, 0))

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

	for data in [["LegL", -0.24], ["LegR", 0.24]]:
		var leg := _pivot(root, data[0], Vector3(data[1], 0.28, 0))
		cap(leg, Vector3(0.26, 0.34, 0.28), COL.horn, Vector3(0, -0.12, 0))

	# corpão redondo (cabeça e corpo juntos)
	blob(root, Vector3(1.05, 1.05, 0.9), col, Vector3(0, 0.78, 0))
	# chifrinhos arredondados
	cap(root, Vector3(0.16, 0.3, 0.16), COL.horn, Vector3(-0.3, 1.3, 0), true, "", Vector3(0, 0, 15))
	cap(root, Vector3(0.16, 0.3, 0.16), COL.horn, Vector3(0.3, 1.3, 0), true, "", Vector3(0, 0, -15))
	# olhão único (face +Z)
	blob(root, Vector3(0.5, 0.46, 0.1), COL.eye_white, Vector3(0, 0.95, 0.4), false)
	blob(root, Vector3(0.22, 0.26, 0.08), COL.pupil, Vector3(0, 0.94, 0.45), false, "Pupil")
	blob(root, Vector3(0.08, 0.08, 0.05), COL.eye_white, Vector3(0.04, 1.0, 0.49), false)
	cap(root, Vector3(0.1, 0.34, 0.05), COL.mouth, Vector3(0, 0.55, 0.43), false, "", Vector3(0, 0, 90))
	for data in [["ArmL", -0.58], ["ArmR", 0.58]]:
		var arm := _pivot(root, data[0], Vector3(data[1], 0.95, 0))
		cap(arm, Vector3(0.22, 0.5, 0.24), col, Vector3(0, -0.2, 0))

	_anim_player(model, _humanoid_anims())
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model


static func build_yeti(body_scale := 1.0, boss := false) -> Node3D:
	## Yeti fofo e fortão: pelagem branca (azulada no chefe), pés de gelo.
	var model := Node3D.new()
	model.name = "YetiModel"
	var root := _pivot(model, "Root", Vector3.ZERO)
	var fur: Color = COL.yeti_boss if boss else COL.yeti

	for data in [["LegL", -0.28], ["LegR", 0.28]]:
		var leg := _pivot(root, data[0], Vector3(data[1], 0.34, 0))
		cap(leg, Vector3(0.38, 0.4, 0.38), fur, Vector3(0, -0.1, 0))
		blob(leg, Vector3(0.46, 0.2, 0.6), COL.ice, Vector3(0, -0.25, 0.08))

	blob(root, Vector3(1.25, 1.3, 1.05), fur, Vector3(0, 0.92, 0))
	blob(root, Vector3(0.8, 0.8, 0.12), fur.darkened(0.05), Vector3(0, 0.75, 0.46), false)  # barriga
	# cabeça peluda com rosto azul-gelo
	blob(root, Vector3(0.95, 0.8, 0.75), fur, Vector3(0, 1.62, 0.02))
	blob(root, Vector3(0.7, 0.5, 0.12), COL.yeti_face, Vector3(0, 1.58, 0.36), false)
	for x in [-0.17, 0.17]:
		blob(root, Vector3(0.12, 0.16, 0.05), COL.pupil, Vector3(x, 1.64, 0.43), false)
		blob(root, Vector3(0.05, 0.06, 0.03), COL.eye_white, Vector3(x + 0.02, 1.68, 0.46), false)
	blob(root, Vector3(0.3, 0.14, 0.06), COL.mouth, Vector3(0, 1.43, 0.43), false)
	for x in [-0.07, 0.07]:
		blob(root, Vector3(0.08, 0.09, 0.04), COL.eye_white, Vector3(x, 1.47, 0.46), false)
	# tufos de pelo / chifres de gelo no chefe
	for x in [-0.25, 0.0, 0.25]:
		blob(root, Vector3(0.28, 0.3, 0.28), fur, Vector3(x, 2.05, -0.02))
	if boss:
		cap(root, Vector3(0.2, 0.5, 0.2), COL.ice, Vector3(-0.45, 2.05, 0), true, "", Vector3(0, 0, 25))
		cap(root, Vector3(0.2, 0.5, 0.2), COL.ice, Vector3(0.45, 2.05, 0), true, "", Vector3(0, 0, -25))
	for data in [["ArmL", -0.75], ["ArmR", 0.75]]:
		var arm := _pivot(root, data[0], Vector3(data[1], 1.25, 0))
		cap(arm, Vector3(0.34, 0.8, 0.34), fur, Vector3(0, -0.32, 0))
		blob(arm, Vector3(0.4, 0.36, 0.4), COL.ice, Vector3(0, -0.72, 0))

	_anim_player(model, _humanoid_anims())
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model


static func _simple_anims(tilt := 0.0) -> Dictionary:
	## Animações leves (balanço) para modelos sem membros: nave.
	var idle := Animation.new()
	idle.length = 1.6
	idle.loop_mode = Animation.LOOP_LINEAR
	_track(idle, "Root:rotation", [[0.0, Vector3(0, 0, 0.06)], [0.8, Vector3(0, 0, -0.06)], [1.6, Vector3(0, 0, 0.06)]])
	var run := Animation.new()
	run.length = 0.6
	run.loop_mode = Animation.LOOP_LINEAR
	_track(run, "Root:rotation", [[0.0, Vector3(tilt, 0, 0.08)], [0.3, Vector3(tilt, 0, -0.08)], [0.6, Vector3(tilt, 0, 0.08)]])
	var attack := Animation.new()
	attack.length = 0.3
	_track(attack, "Root:scale", [[0.0, Vector3.ONE], [0.1, Vector3(1.2, 0.8, 1.2)], [0.3, Vector3.ONE]])
	var die := Animation.new()
	die.length = 0.5
	_track(die, "Root:scale", [[0.0, Vector3.ONE], [0.5, Vector3(1.3, 0.05, 1.3)]])
	return {"idle": idle, "run": run, "attack": attack, "die": die}


static func build_saucer(body_scale := 1.0) -> Node3D:
	## Nave-disco com um alienzinho na cúpula de vidro (o modelo paira no ar).
	var model := Node3D.new()
	model.name = "SaucerModel"
	var root := _pivot(model, "Root", Vector3.ZERO)
	blob(root, Vector3(1.5, 0.42, 1.5), COL.saucer, Vector3(0, 0.45, 0))
	blob(root, Vector3(0.9, 0.12, 0.9), COL.gold, Vector3(0, 0.22, 0), false)  # luz de baixo
	for i in range(6):
		var a := i * TAU / 6.0
		blob(root, Vector3(0.14, 0.14, 0.14), COL.gold, Vector3(sin(a) * 0.66, 0.46, cos(a) * 0.66), false)
	blob(root, Vector3(0.86, 0.7, 0.86), COL.glass, Vector3(0, 0.82, 0))
	blob(root, Vector3(0.44, 0.4, 0.4), COL.alien, Vector3(0, 0.8, 0), false)
	for x in [-0.1, 0.1]:
		blob(root, Vector3(0.1, 0.14, 0.05), COL.pupil, Vector3(x, 0.83, 0.17), false, "", Vector3(0, 0, -x * 160))
	_anim_player(model, _simple_anims(0.25))
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model


static func build_alien(body_scale := 1.0, dad := false) -> Node3D:
	## Alien verdinho de olhão preto e antenas. dad = o pai (chefe), maior e mais escuro.
	var model := Node3D.new()
	model.name = "AlienModel"
	var root := _pivot(model, "Root", Vector3.ZERO)
	var col: Color = COL.alien_dad if dad else COL.alien_mini
	for data in [["LegL", -0.17], ["LegR", 0.17]]:
		var leg := _pivot(root, data[0], Vector3(data[1], 0.36, 0))
		cap(leg, Vector3(0.2, 0.4, 0.2), col, Vector3(0, -0.14, 0))
		blob(leg, Vector3(0.26, 0.14, 0.34), col.darkened(0.15), Vector3(0, -0.3, 0.05))
	blob(root, Vector3(0.62, 0.62, 0.5), col, Vector3(0, 0.62, 0))
	if dad:
		blob(root, Vector3(0.4, 0.4, 0.1), col.lightened(0.18), Vector3(0, 0.6, 0.22), false)  # barriga
	for data in [["ArmL", -0.38], ["ArmR", 0.38]]:
		var arm := _pivot(root, data[0], Vector3(data[1], 0.8, 0))
		cap(arm, Vector3(0.15, 0.5, 0.15), col, Vector3(0, -0.2, 0))
		blob(arm, Vector3(0.18, 0.18, 0.18), col, Vector3(0, -0.45, 0))
	var head := _pivot(root, "Head", Vector3(0, 0.95, 0))
	blob(head, Vector3(0.95, 0.8, 0.8), col, Vector3(0, 0.4, 0))
	for side in [-1.0, 1.0]:  # olhão preto de amêndoa com brilho
		blob(head, Vector3(0.3, 0.38, 0.1), COL.pupil, Vector3(0.2 * side, 0.38, 0.34), false, "", Vector3(0, 0, 22 * side))
		blob(head, Vector3(0.08, 0.1, 0.05), COL.eye_white, Vector3(0.23 * side, 0.46, 0.4), false)
		cap(head, Vector3(0.05, 0.3, 0.05), col, Vector3(0.22 * side, 0.9, 0.0), false, "", Vector3(0, 0, -22 * side))
		blob(head, Vector3(0.14, 0.14, 0.14), COL.gold if dad else COL.cheek, Vector3(0.33 * side, 1.06, 0.0), false)
	blob(head, Vector3(0.18, 0.07, 0.05), COL.mouth, Vector3(0, 0.12, 0.38), false)
	_anim_player(model, _humanoid_anims())
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model


static func build_egg(parent: Node3D) -> void:
	blob(parent, Vector3(0.52, 0.68, 0.52), COL.egg, Vector3(0, 0.34, 0))
	for p in [Vector3(0.16, 0.45, 0.2), Vector3(-0.14, 0.3, 0.2), Vector3(0.05, 0.55, -0.22)]:
		blob(parent, Vector3(0.13, 0.13, 0.08), Color(0.6, 0.4, 0.85), p, false)


static func build_gorilla(body_scale := 1.0, boss := false) -> Node3D:
	## Gorila fortão de braços enormes (o chefe é "costas-prateadas").
	var model := Node3D.new()
	model.name = "GorillaModel"
	var root := _pivot(model, "Root", Vector3.ZERO)
	var fur: Color = COL.gorilla_boss if boss else COL.gorilla
	for data in [["LegL", -0.3], ["LegR", 0.3]]:
		var leg := _pivot(root, data[0], Vector3(data[1], 0.4, 0))
		cap(leg, Vector3(0.42, 0.5, 0.42), fur.darkened(0.1), Vector3(0, -0.12, 0))
		blob(leg, Vector3(0.5, 0.2, 0.62), fur.darkened(0.3), Vector3(0, -0.3, 0.08))
	blob(root, Vector3(1.4, 1.25, 1.05), fur, Vector3(0, 0.98, 0))
	blob(root, Vector3(0.95, 0.85, 0.14), COL.gorilla_face.darkened(0.1), Vector3(0, 0.95, 0.5), false)  # peitoral
	var head := _pivot(root, "Head", Vector3(0, 1.5, 0.12))
	blob(head, Vector3(0.8, 0.7, 0.7), fur, Vector3(0, 0.18, 0))
	blob(head, Vector3(0.6, 0.45, 0.2), COL.gorilla_face, Vector3(0, 0.1, 0.3), false)  # focinho
	blob(head, Vector3(0.7, 0.14, 0.2), fur.darkened(0.25), Vector3(0, 0.34, 0.28), false)  # sobrancelha
	for x in [-0.17, 0.17]:
		blob(head, Vector3(0.13, 0.15, 0.05), COL.eye_white, Vector3(x, 0.24, 0.36), false)
		blob(head, Vector3(0.07, 0.1, 0.05), COL.pupil, Vector3(x, 0.23, 0.39), false)
		blob(head, Vector3(0.07, 0.05, 0.05), COL.pupil, Vector3(x * 0.55, 0.12, 0.41), false)  # narinas
	blob(head, Vector3(0.3, 0.08, 0.05), COL.mouth, Vector3(0, -0.02, 0.4), false)
	for data in [["ArmL", -0.88], ["ArmR", 0.88]]:
		var arm := _pivot(root, data[0], Vector3(data[1], 1.35, 0))
		cap(arm, Vector3(0.46, 1.1, 0.46), fur, Vector3(0, -0.45, 0))
		blob(arm, Vector3(0.58, 0.5, 0.58), fur.darkened(0.15), Vector3(0, -0.98, 0.05))
	_anim_player(model, _humanoid_anims())
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model


static func build_tree_missile(parent: Node3D) -> void:
	## Árvore voando (deitada, copa na frente) que o gorila arremessa.
	cap(parent, Vector3(0.5, 2.6, 0.5), Color(0.5, 0.33, 0.2), Vector3(0, 0.9, -0.2), true, "", Vector3(90, 0, 0))
	var green := Color(0.2, 0.6, 0.28)
	blob(parent, Vector3(1.8, 1.5, 1.8), green, Vector3(0, 0.95, 1.2))
	blob(parent, Vector3(1.2, 1.0, 1.2), green.lightened(0.12), Vector3(0.3, 1.5, 1.3))


static func build_octopus(body_scale := 1.0, boss := false) -> Node3D:
	## Polvo fofo: cabeça de cúpula, olhões e 6 tentáculos que balançam.
	var model := Node3D.new()
	model.name = "OctopusModel"
	var root := _pivot(model, "Root", Vector3.ZERO)
	var col: Color = COL.octopus_boss if boss else COL.octopus

	var tent_anims := []
	for i in range(6):
		var ang := i * TAU / 6.0
		var t := _pivot(root, "T%d" % i, Vector3(sin(ang) * 0.42, 0.3, cos(ang) * 0.38))
		t.rotation = Vector3(cos(ang) * 0.5, 0, -sin(ang) * 0.5)
		cap(t, Vector3(0.2, 0.55, 0.2), col, Vector3(0, -0.05, 0))
		blob(t, Vector3(0.22, 0.22, 0.22), col, Vector3(0, -0.3, 0))
		tent_anims.append([i, t.rotation])

	blob(root, Vector3(1.15, 1.05, 1.05), col, Vector3(0, 0.82, 0))
	for x in [-0.24, 0.24]:
		blob(root, Vector3(0.34, 0.38, 0.14), COL.eye_white, Vector3(x, 0.92, 0.45), false)
		blob(root, Vector3(0.16, 0.2, 0.08), COL.pupil, Vector3(x * 0.95, 0.9, 0.52), false, "Pupil" if x > 0 else "")
		blob(root, Vector3(0.06, 0.07, 0.04), COL.eye_white, Vector3(x * 0.95 + 0.03, 0.97, 0.56), false)
		blob(root, Vector3(0.16, 0.09, 0.05), COL.cheek, Vector3(x * 1.6, 0.68, 0.45), false)
	cap(root, Vector3(0.09, 0.16, 0.04), COL.mouth, Vector3(0, 0.66, 0.5), false, "", Vector3(0, 0, 90))
	if boss:  # coroa dourada
		for x in [-0.28, 0.0, 0.28]:
			blob(root, Vector3(0.16, 0.22, 0.16), COL.gold, Vector3(x, 1.4 + (0.06 if x == 0.0 else 0.0), 0))
		cap(root, Vector3(0.14, 0.7, 0.14), COL.gold, Vector3(0, 1.32, 0), true, "", Vector3(0, 0, 90))

	var idle := Animation.new()
	idle.length = 1.2
	idle.loop_mode = Animation.LOOP_LINEAR
	var run := Animation.new()
	run.length = 0.6
	run.loop_mode = Animation.LOOP_LINEAR
	_track(idle, "Root:position", [[0.0, Vector3.ZERO], [0.6, Vector3(0, 0.05, 0)], [1.2, Vector3.ZERO]])
	_track(run, "Root:position", [[0.0, Vector3.ZERO], [0.3, Vector3(0, 0.12, 0)], [0.6, Vector3.ZERO]])
	for ta in tent_anims:
		var r: Vector3 = ta[1]
		var ph: float = 0.35 * (int(ta[0]) % 2 * 2 - 1)
		_track(idle, "Root/T%d:rotation" % ta[0], [[0.0, r], [0.6, r + Vector3(ph, 0, ph)], [1.2, r]])
		_track(run, "Root/T%d:rotation" % ta[0], [[0.0, r + Vector3(ph, 0, 0)], [0.3, r - Vector3(ph, 0, 0)], [0.6, r + Vector3(ph, 0, 0)]])
	var attack := Animation.new()
	attack.length = 0.3
	_track(attack, "Root:scale", [[0.0, Vector3(1.0, 1.0, 1.0)], [0.1, Vector3(0.85, 1.25, 0.85)], [0.3, Vector3.ONE]])
	var die := Animation.new()
	die.length = 0.5
	_track(die, "Root:scale", [[0.0, Vector3.ONE], [0.5, Vector3(1.2, 0.08, 1.2)]])
	_anim_player(model, {"idle": idle, "run": run, "attack": attack, "die": die})
	if body_scale != 1.0:
		model.scale = Vector3.ONE * body_scale
	return model
