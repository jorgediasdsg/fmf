extends CharacterBody2D
## Ciclope: patrulha virando em paredes e beiradas; dano por contato;
## morre em puff soltando moedas e XP. Reusado pelo chefe via exports.

@export var hp := 6
@export var contact_damage := 2
@export var speed := 30.0
@export var xp_reward := 8
@export var coin_min := 2
@export var coin_max := 4

const CoinScene := preload("res://src/items/coin_pickup.tscn")

var dir := -1
var _flash := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var hurtbox: Area2D = $Hurtbox


func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = dir * speed
	if is_on_wall():
		dir *= -1
	elif is_on_floor() and speed > 0.0 and not ledge_ray.is_colliding():
		dir *= -1
	ledge_ray.position.x = 10 * dir
	sprite.flip_h = dir > 0

	_flash -= delta
	sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE

	for body in hurtbox.get_overlapping_bodies():
		if body.has_method("hurt"):
			var push := signf(body.global_position.x - global_position.x)
			body.hurt(contact_damage, 1.0 if push == 0.0 else push)
	move_and_slide()


func take_hit(damage: int, from_dir: float) -> void:
	hp -= damage
	_flash = 0.15
	velocity.x += from_dir * 40.0
	Sfx.play("hit", -4.0)
	if hp <= 0:
		_die()


func _die() -> void:
	var parent := get_parent()
	var rng := RandomNumberGenerator.new()
	for i in range(rng.randi_range(coin_min, coin_max)):
		var coin := CoinScene.instantiate()
		coin.position = global_position + Vector2(rng.randf_range(-10, 10), -10 - i * 4)
		parent.call_deferred("add_child", coin)
	_puff(parent)
	GameState.add_xp(xp_reward)
	queue_free()


func _puff(parent: Node) -> void:
	var p := CPUParticles2D.new()
	p.position = global_position + Vector2(0, -10)
	p.one_shot = true
	p.amount = 14
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2(0, 60)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.95, 0.9, 0.8)
	p.emitting = true
	parent.call_deferred("add_child", p)
	var t := Timer.new()
	t.wait_time = 1.0
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(p.queue_free)
	p.add_child(t)
