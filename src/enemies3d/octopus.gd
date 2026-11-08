extends "res://src/enemies3d/cyclops.gd"
## Polvo: vagueia; se vê o Zack (e ele não está escondido no mato) mantém
## distância e cospe tinta, avisando com um "inchaço" antes. O chefe cospe
## três bolas em leque.

const InkScene := preload("res://src/enemies3d/ink.tscn")

@export var shoot_interval := 2.8
@export var shoot_range := 9.0
@export var keep_distance := 3.5
@export var ink_damage := 2
@export var ink_speed := 7.0
@export var fan := false

const TELEGRAPH := 0.55

var _shoot_t := 1.5
var _orbit := 1.0 if randf() > 0.5 else -1.0  # cada polvo contorna para um lado


func _base_scale() -> float:
	return 2.0 if boss else 1.0


func _make_model() -> Node3D:
	return CharacterBuilder.build_octopus(_base_scale(), boss)


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	_alert -= delta
	_call_t -= delta
	var player := _target()
	var dir := Vector3.ZERO
	var base := Vector3.ONE * _base_scale()
	var seen := _can_see(player)
	var to_player := Vector3.ZERO
	if seen:
		to_player = player.global_position - global_position
		to_player.y = 0.0
	if seen and to_player.length() < _chase_limit():
		var dist := to_player.length()
		if dist < contact_range and player.has_method("hurt"):
			player.hurt(contact_damage, global_position)
		if _call_t <= 0.0 and dist < chase_range:
			_call_t = 1.0
			_call_allies()
		if dist < shoot_range:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(to_player.x, to_player.z), 8.0 * delta)
			if dist > keep_distance + 1.0:
				dir = to_player.normalized()          # fecha o cerco
			elif dist > keep_distance:
				dir = to_player.normalized() * 0.5 + to_player.normalized().cross(Vector3.UP) * _orbit * 0.6
			else:
				dir = to_player.normalized().cross(Vector3.UP) * _orbit * 0.7  # gira em volta
			_shoot_t -= delta
			if _shoot_t < TELEGRAPH:
				model.scale = base * (1.0 + 0.1 * sin(_shoot_t * 40.0))
			if _shoot_t <= 0.0:
				_shoot_t = shoot_interval
				model.scale = base
				_shoot(to_player.normalized())
		else:
			dir = to_player.normalized()  # alertado: vem com tudo atrás do herói
			_shoot_t = maxf(_shoot_t, TELEGRAPH + 0.2)
	else:
		model.scale = base
		_shoot_t = maxf(_shoot_t, 1.0)
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(1.5, 3.0)
			_wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() \
				if randf() > 0.3 else Vector3.ZERO
		dir = _wander_dir * 0.4
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.length() > 0.05:
		if not (seen and to_player.length() < shoot_range):
			model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
		if anim.current_animation != "run":
			anim.play("run")
	elif anim.current_animation != "idle":
		anim.play("idle")
	move_and_slide()


func _shoot(dir: Vector3) -> void:
	var angles := [-0.35, 0.0, 0.35] if fan else [0.0]
	for a in angles:
		var ink := InkScene.instantiate()
		ink.direction = dir.rotated(Vector3.UP, a)
		ink.speed = ink_speed
		ink.damage = ink_damage
		ink.position = global_position + Vector3(0, 0.9 * _base_scale(), 0) + dir * 0.8 * _base_scale()
		get_parent().add_child(ink)
	Sfx.play("hit", -10.0)
