extends "res://src/enemies3d/cyclops.gd"
## Gorila Rei: muita vida. A cada 5 s (avisando antes) arremessa DUAS árvores
## em direções levemente diferentes, na direção do herói. Cada árvore tira
## metade da vida; dá para desviar de lado ou pular por cima.

const TreeScene := preload("res://src/enemies3d/tree_missile.tscn")
const THROW_INTERVAL := 5.0
const TELEGRAPH := 0.7

var _throw_t := 3.0


func _base_scale() -> float:
	return 2.0


func _make_model() -> Node3D:
	return CharacterBuilder.build_gorilla(_base_scale(), true)


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0
	_alert -= delta
	var target := _target()
	var dir := Vector3.ZERO
	var base := Vector3.ONE * _base_scale()
	if target != null:
		var to := target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		model.rotation.y = lerp_angle(model.rotation.y, atan2(to.x, to.z), 6.0 * delta)
		if dist < 6.0:
			dir = -to.normalized() * 0.7
		elif dist > 12.0:
			dir = to.normalized()
		else:
			dir = to.normalized().cross(Vector3.UP) * 0.5
		if dist < contact_range and target.has_method("hurt"):
			target.hurt(contact_damage, global_position)
		if dist < 22.0:
			_throw_t -= delta
			if _throw_t < TELEGRAPH:
				model.scale = base * (1.0 + 0.1 * sin(_throw_t * 40.0))
			if _throw_t <= 0.0:
				_throw_t = THROW_INTERVAL
				model.scale = base
				_throw_trees(to.normalized(), target.global_position)
	else:
		model.scale = base
		_throw_t = maxf(_throw_t, TELEGRAPH + 0.3)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.length() > 0.05:
		if anim.current_animation != "run":
			anim.play("run")
	elif anim.current_animation != "idle":
		anim.play("idle")
	move_and_slide()


func _throw_trees(to: Vector3, aim: Vector3) -> void:
	## Duas árvores saem de lados opostos do gorila e se cruzam em cima de onde o
	## herói estava: parado, ele leva as duas; saia de lado ou pule.
	var side := to.cross(Vector3.UP).normalized()
	for sgn: float in [-1.0, 1.0]:
		var start := global_position + Vector3(0, 0.1, 0) + to * 1.8 + side * sgn * 3.0
		var dir := Vector3(aim.x - start.x, 0.0, aim.z - start.z).normalized()
		var t := TreeScene.instantiate()
		t.direction = dir
		get_parent().add_child(t)
		t.global_position = start
	Sfx.play("boss_roar", -6.0)
