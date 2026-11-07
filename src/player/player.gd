class_name Player
extends CharacterBody2D
## Zack: andar, pular (coyote + buffer), golpe de espada, dano com i-frames.

signal died

const SPEED := 130.0
const JUMP_VELOCITY := -300.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1
const ATTACK_ACTIVE := 0.15
const ATTACK_COOLDOWN := 0.35
const IFRAME_TIME := 1.0
const KNOCKBACK := Vector2(130.0, -160.0)

var facing := 1
var _coyote := 0.0
var _jump_buffer := 0.0
var _attack_active := 0.0
var _attack_cd := 0.0
var _iframes := 0.0
var _dead := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sword: Area2D = $SwordHitbox
@onready var sfx_jump: AudioStreamPlayer = $SfxJump
@onready var sfx_swing: AudioStreamPlayer = $SfxSwing
@onready var sfx_hurt: AudioStreamPlayer = $SfxHurt


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	if not is_on_floor():
		velocity.y += gravity * delta
		_coyote -= delta
	else:
		_coyote = COYOTE_TIME

	_attack_cd -= delta
	_attack_active -= delta
	_iframes -= delta
	_jump_buffer -= delta
	if _attack_active <= 0.0:
		sword.monitoring = false

	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * SPEED
	if axis != 0.0:
		facing = 1 if axis > 0.0 else -1
		sprite.flip_h = facing < 0
		sword.scale.x = facing

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0
		sfx_jump.play()

	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_attack_cd = ATTACK_COOLDOWN
		_attack_active = ATTACK_ACTIVE
		sword.monitoring = true
		sfx_swing.play()
		sprite.play("attack")

	move_and_slide()
	_update_visuals()


func _update_visuals() -> void:
	# pisca durante os i-frames
	sprite.visible = _iframes <= 0.0 or fmod(_iframes, 0.16) < 0.08
	if _attack_active > 0.0:
		return
	if not is_on_floor():
		sprite.play("jump")
	elif absf(velocity.x) > 5.0:
		sprite.play("run")
	else:
		sprite.play("idle")


func hurt(damage: int, from_dir: float) -> void:
	if _dead or _iframes > 0.0:
		return
	_iframes = IFRAME_TIME
	velocity = Vector2(KNOCKBACK.x * signf(from_dir), KNOCKBACK.y)
	sfx_hurt.play()
	if GameState.take_damage(damage):
		_die()


func _die() -> void:
	_dead = true
	sprite.visible = true
	sprite.play("jump")
	sprite.modulate = Color(1.0, 0.6, 0.6)
	died.emit()
