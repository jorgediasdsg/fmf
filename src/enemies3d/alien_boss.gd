extends "res://src/enemies3d/cyclops.gd"
## Alien Pai: mantém distância e joga um ovo a cada 5 s no herói; do ovo saem
## 5 mini aliens. Morre com 7 golpes (fixed_hits).

const EggScene := preload("res://src/enemies3d/egg.tscn")
const EGG_INTERVAL := 5.0
const TELEGRAPH := 0.7

var _egg_t := 3.0


func _base_scale() -> float:
	return 2.0


func _make_model() -> Node3D:
	return CharacterBuilder.build_alien(_base_scale(), true)


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
		if dist < 5.0:
			dir = -to.normalized() * 0.8       # recua: a luta é de longe
		elif dist > 11.0:
			dir = to.normalized()
		else:
			dir = to.normalized().cross(Vector3.UP) * 0.5  # circula
		if dist < contact_range and target.has_method("hurt"):
			target.hurt(contact_damage, global_position)
		if dist < 18.0:
			_egg_t -= delta
			if _egg_t < TELEGRAPH:
				model.scale = base * (1.0 + 0.1 * sin(_egg_t * 40.0))
			if _egg_t <= 0.0:
				_egg_t = EGG_INTERVAL
				model.scale = base
				_throw_egg(target.global_position)
	else:
		model.scale = base
		_egg_t = maxf(_egg_t, TELEGRAPH + 0.3)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.length() > 0.05:
		if anim.current_animation != "run":
			anim.play("run")
	elif anim.current_animation != "idle":
		anim.play("idle")
	move_and_slide()


func _throw_egg(at: Vector3) -> void:
	var egg := EggScene.instantiate()
	egg.start = global_position + Vector3(0, 2.4, 0)
	egg.target = Vector3(at.x, 0.0, at.z)
	get_parent().add_child(egg)
	Sfx.play("hit", -6.0)
