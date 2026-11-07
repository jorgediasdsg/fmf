class_name Player3D
extends CharacterBody3D
## Zack em 3D: movimento em 8 direções no plano XZ, câmera alta inclinada
## que segue com suavização, dano com i-frames e knockback.

signal died

const SPEED := 6.0
const IFRAME_TIME := 1.0
const KNOCKBACK := 8.0
const CAM_LERP := 8.0

var facing := Vector3.FORWARD
var _iframes := 0.0
var _dead := false

@onready var body: Node3D = $Body
@onready var rig: Node3D = $CameraRig


func _ready() -> void:
	add_to_group("player")
	rig.top_level = true
	rig.global_position = global_position
	var cam: Camera3D = $CameraRig/Camera
	cam.position = Vector3(0, 11.0, 10.2)
	cam.rotation_degrees.x = -48.0
	var mesh := $Body/Mesh as MeshInstance3D
	if mesh != null:
		mesh.material_override = ToonMaterial.flat(Color(0.82, 0.27, 0.28))
		ToonMaterial.add_outline(mesh)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	_iframes -= delta
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
