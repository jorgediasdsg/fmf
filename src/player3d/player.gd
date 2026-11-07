class_name Player3D
extends CharacterBody3D
## Zack em 3D: movimento em 8 direções no plano XZ, câmera alta inclinada
## que segue com suavização, dano com i-frames e knockback.

signal died

const SPEED := 6.0
const IFRAME_TIME := 1.0
const KNOCKBACK := 8.0
const CAM_LERP := 8.0
const ATTACK_ACTIVE := 0.2
const ATTACK_COOLDOWN := 0.4

var facing := Vector3.FORWARD
var anim: AnimationPlayer
var _iframes := 0.0
var _attack_active := 0.0
var _attack_cd := 0.0
var _dead := false

@onready var body: Node3D = $Body
@onready var rig: Node3D = $CameraRig
@onready var sword: Area3D = $Body/SwordArea


func _ready() -> void:
	add_to_group("player")
	rig.top_level = true
	rig.global_position = global_position
	var cam: Camera3D = $CameraRig/Camera
	cam.position = Vector3(0, 11.0, 10.2)
	cam.rotation_degrees.x = -48.0
	var placeholder := body.get_node_or_null("Mesh")
	if placeholder != null:
		placeholder.queue_free()
	var model := CharacterBuilder.build_zack()
	body.add_child(model)
	anim = model.get_node("Anim")
	anim.play("idle")
	sword.body_entered.connect(_on_sword_hit)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	_iframes -= delta
	_attack_cd -= delta
	_attack_active -= delta
	if _attack_active <= 0.0:
		sword.monitoring = false
	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_attack_cd = ATTACK_COOLDOWN
		_attack_active = ATTACK_ACTIVE
		sword.monitoring = true
		Sfx.play("hit", -8.0)
		if anim != null:
			anim.play("attack")

	var input := Vector3(
		Input.get_axis("move_left", "move_right"), 0.0,
		Input.get_axis("move_up", "move_down"))
	if input.length() > 1.0:
		input = input.normalized()

	if _iframes < IFRAME_TIME - 0.25:  # fora do empurrão inicial do knockback
		velocity.x = input.x * SPEED
		velocity.z = input.z * SPEED
	if input.length() > 0.1:
		facing = input.normalized()
	body.rotation.y = lerp_angle(body.rotation.y, atan2(facing.x, facing.z), 14.0 * delta)

	move_and_slide()
	body.visible = _iframes <= 0.0 or fmod(_iframes, 0.16) < 0.08
	if anim != null and anim.current_animation != "attack":
		var moving := Vector2(velocity.x, velocity.z).length() > 0.5
		var target := "run" if moving else "idle"
		if anim.current_animation != target:
			anim.play(target)


func _on_sword_hit(hit_body: Node) -> void:
	if hit_body.has_method("take_hit"):
		hit_body.take_hit(GameState.attack_damage(), global_position)


func _process(delta: float) -> void:
	rig.global_position = rig.global_position.lerp(global_position, CAM_LERP * delta)


func hurt(damage: int, from_pos: Vector3) -> void:
	if _dead or _iframes > 0.0:
		return
	_iframes = IFRAME_TIME
	var dir := (global_position - from_pos)
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.BACK
	velocity = dir * KNOCKBACK
	Sfx.play("hurt")
	if GameState.take_damage(damage):
		_die()


func _die() -> void:
	_dead = true
	body.visible = true
	died.emit()
