extends CharacterBody3D
## Ciclope 3D: vagueia; persegue o player a <8 m; dano por contato;
## morre soltando moedas e XP. O chefe reusa via exports/herança.

signal defeated

@export var hp := 6
@export var contact_damage := 2
@export var speed := 2.5
@export var xp_reward := 8
@export var coin_min := 2
@export var coin_max := 4
@export var chase_range := 8.0
@export var contact_range := 1.0
@export var boss := false

const CoinScene := preload("res://src/items3d/coin.tscn")

var _wander_dir := Vector3.ZERO
var _wander_t := 0.0
var _dying := false
var model: Node3D
var anim: AnimationPlayer


func _ready() -> void:
	add_to_group("enemies")
	model = CharacterBuilder.build_cyclops(2.2 if boss else 1.0, boss)
	add_child(model)
	anim = model.get_node("Anim")
	anim.play("idle")


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var dir := Vector3.ZERO
	if player != null:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() < contact_range and player.has_method("hurt"):
			player.hurt(contact_damage, global_position)
		if to_player.length() < chase_range:
			dir = to_player.normalized()
		else:
			_wander_t -= delta
			if _wander_t <= 0.0:
				_wander_t = randf_range(1.5, 3.0)
				_wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() \
					if randf() > 0.3 else Vector3.ZERO
			dir = _wander_dir * 0.4
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.length() > 0.05:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
		if anim.current_animation != "run":
			anim.play("run")
	elif anim.current_animation != "idle":
		anim.play("idle")
	move_and_slide()


func take_hit(damage: int, from_pos: Vector3) -> void:
	if _dying:
		return
	hp -= damage
	var push := global_position - from_pos
	push.y = 0.0
	if push.length() > 0.01:
		velocity += push.normalized() * 5.0
	_punch_scale()
	Sfx.play("hit", -4.0)
	if hp <= 0:
		_die()


func _punch_scale() -> void:
	var base := Vector3.ONE * (2.2 if boss else 1.0)
	model.scale = base * 1.18
	var tw := create_tween()
	tw.tween_property(model, "scale", base, 0.12)


func _die() -> void:
	_dying = true
	defeated.emit()
	var parent := get_parent()
	var rng := RandomNumberGenerator.new()
	for i in range(rng.randi_range(coin_min, coin_max)):
		var coin := CoinScene.instantiate()
		coin.position = global_position + Vector3(rng.randf_range(-0.7, 0.7), 0.4,
			rng.randf_range(-0.7, 0.7))
		parent.call_deferred("add_child", coin)
	_puff(parent)
	GameState.add_xp(xp_reward)
	if boss:
		Sfx.play("boss_roar")
	anim.play("die")
	set_collision_layer_value(3, false)
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _puff(parent: Node) -> void:
	var p := CPUParticles3D.new()
	p.position = global_position + Vector3(0, 0.6, 0)
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -3, 0)
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.3
	p.mesh = BoxMesh.new()
	(p.mesh as BoxMesh).size = Vector3.ONE * 0.18
	p.emitting = true
	parent.call_deferred("add_child", p)
	var t := Timer.new()
	t.wait_time = 1.2
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(p.queue_free)
	p.add_child(t)
