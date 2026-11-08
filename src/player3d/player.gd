class_name Player3D
extends CharacterBody3D
## Zack em 3D: movimento em 8 direções no plano XZ, câmera alta inclinada
## que segue com suavização, dano com i-frames e knockback.

signal died

const SPEED := 6.0
const RUN_SPEED := 10.5
const JUMP_VELOCITY := 8.0
# Barra de força: golpes e pulos gastam, correr drena, parado recupera, andando fica estável
const STAMINA_MAX := 100.0
const COST_PUNCH := 8.0
const COST_KICK := 18.0
const COST_JUMP := 8.0
const COST_SUPER_PUNCH := 22.0
const COST_FLY_KICK := 24.0
const COST_SHOT := 6.0
const RUN_DRAIN := 14.0     # por segundo correndo
const REGEN := 30.0         # por segundo parado
const REGEN_DELAY := 0.45
const SPECIAL_MAX := 100.0
const SPECIAL_RANGE := 20.0   # "na tela": bichos até essa distância   # pausa depois de gastar antes de recuperar
const IFRAME_TIME := 1.0
const KNOCKBACK := 8.0
const CAM_LERP := 8.0
const ATTACK_ACTIVE := 0.2
const ATTACK_COOLDOWN := 0.4
const REVEAL_TIME := 1.2
const LEASH := 13.0        # no co-op, não dá para se afastar além disso
const DEADZONE := 0.3        # analógico: abaixo disso é "solto" (evita virar à toa)
const FACE_MIN := 0.25       # só muda a direção do olhar com o analógico firme
const KICK_RANGE := 2.2     # com rifle: bicho mais perto que isso leva chute
const SHOT_COOLDOWN := 0.7
const SHOT_RANGE := 18.0
const BulletScene := preload("res://src/items3d/bullet.tscn")

var player_id := 1         # 1 = teclado/toque, 2 = controle (co-op)
var use_test_input := false  # simulações: ignora o teclado/controle
var test_move := Vector2.ZERO
var test_pressed := {}   # simulação: ações "apertadas agora" (consumidas) e "run" segurada
var test_attack := false  # atalho: soco
var facing := Vector3.FORWARD
var anim: AnimationPlayer
var _iframes := 0.0
var _attack_active := 0.0
var _attack_cd := 0.0
var _dead := false
var _bushes := 0           # quantas moitas cobrem o Zack agora
var _reveal := 0.0         # atacar de dentro da moita revela por um instante
var _hide_label: Label3D
var _prev_pad_attack := false
var _rifle_attached := false
var _shot_cd := 0.0
var stamina := STAMINA_MAX
var _regen_wait := 0.0
var _action := ""          # golpe especial em andamento: "superpunch" / "flykick"
var _action_t := 0.0
var _dash_vel := Vector3.ZERO
var _air_run := false      # estava correndo ao pular (habilita a voadora)
var special := 0.0         # barra de especial: enche ao bater
var _dmg_mult := 1.0       # multiplicador do golpe atual
var _pad_prev := {}

@onready var body: Node3D = $Body
@onready var rig: Node3D = get_node_or_null("CameraRig")
@onready var sword: Area3D = $Body/SwordArea


func _ready() -> void:
	add_to_group("player")
	if player_id == 2:
		rig.queue_free()  # só o jogador 1 tem câmera; ela acompanha os dois
		rig = null
	else:
		rig.top_level = true
		rig.global_position = global_position
		var cam: Camera3D = $CameraRig/Camera
		cam.position = Vector3(0, 11.0, 10.2)
		cam.rotation_degrees.x = -48.0
	var placeholder := body.get_node_or_null("Mesh")
	if placeholder != null:
		placeholder.queue_free()
	var model := CharacterBuilder.build_hero(GameState.character2 if player_id == 2 else GameState.character)
	body.add_child(model)
	anim = model.get_node("Anim")
	anim.play("idle")
	sword.body_entered.connect(_on_sword_hit)
	_hide_label = Label3D.new()
	_hide_label.text = "Escondido!"
	_hide_label.font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	_hide_label.font_size = 28
	_hide_label.pixel_size = 0.012
	_hide_label.outline_size = 10
	_hide_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hide_label.no_depth_test = true
	_hide_label.position = Vector3(0, 2.6, 0)
	_hide_label.modulate = Color(0.6, 1.0, 0.65)
	_hide_label.visible = false
	add_child(_hide_label)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	_iframes -= delta
	_shot_cd -= delta
	_reveal -= delta
	_attack_cd -= delta
	_attack_active -= delta
	_action_t -= delta
	_regen_wait -= delta
	if GameState.has_rifle and not _rifle_attached:
		_attach_rifle()
	if _attack_active <= 0.0:
		sword.monitoring = false
		sword.scale = Vector3.ONE
	if _action_t <= 0.0:
		_action = ""

	var mv := _read_move()
	var input := Vector3(mv.x, 0.0, mv.y)
	if input.length() > 1.0:
		input = input.normalized()
	var on_floor := is_on_floor()
	var running := _held("run") and input.length() > 0.1 and stamina > 5.0 and _action == ""

	# --- pulo
	if _just("jump") and on_floor and _action == "" and stamina >= COST_JUMP:
		velocity.y = JUMP_VELOCITY
		_spend(COST_JUMP)
		_air_run = running
		if anim != null:
			anim.play("jump")
	if on_floor and velocity.y <= 0.0 and _action == "":
		_air_run = false

	# --- golpes (soco = braço, chute = perna; correndo viram golpes especiais)
	var punch := _just("punch")
	var kick := _just("kick")
	if _action == "":
		if kick:
			if not on_floor and (_air_run or running) and stamina >= COST_FLY_KICK:
				_start_special("flykick", COST_FLY_KICK, 2.0, 0.5, 11.0)
			elif _attack_cd <= 0.0 and stamina >= COST_KICK:
				_start_attack("attack", COST_KICK, 1.0, 0.2, ATTACK_COOLDOWN)
		elif punch:
			if GameState.has_rifle and _nearest_enemy_dist() > KICK_RANGE and stamina >= COST_SHOT:
				_spend(COST_SHOT)
				_shoot()
			elif on_floor and running and stamina >= COST_SUPER_PUNCH:
				_start_special("superpunch", COST_SUPER_PUNCH, 1.7, 0.3, 9.5)
			elif _attack_cd <= 0.0 and stamina >= COST_PUNCH:
				_start_attack("punch", COST_PUNCH, 0.6, 0.15, 0.25)

	if _just("special") and special >= SPECIAL_MAX:
		_fire_special()

	# --- movimento
	if _action_t > 0.0 and _action != "":
		velocity.x = _dash_vel.x
		velocity.z = _dash_vel.z
	elif _iframes < IFRAME_TIME - 0.25:  # fora do empurrão inicial do knockback
		var spd := RUN_SPEED if running else SPEED
		velocity.x = input.x * spd
		velocity.z = input.z * spd
	if input.length() > FACE_MIN and _action == "":
		facing = input.normalized()
	body.rotation.y = lerp_angle(body.rotation.y, atan2(facing.x, facing.z), 14.0 * delta)

	# --- força: correr drena, andar fica estável, parado recupera
	if running:
		stamina -= RUN_DRAIN * delta
		_regen_wait = REGEN_DELAY
	elif input.length() <= 0.1 and _action == "" and _regen_wait <= 0.0 and on_floor:
		stamina += REGEN * delta
	stamina = clampf(stamina, 0.0, STAMINA_MAX)

	_apply_leash()
	move_and_slide()
	body.visible = _iframes <= 0.0 or fmod(_iframes, 0.16) < 0.08
	_update_hidden_look()
	if anim != null and not _is_action_anim():
		var moving := Vector2(velocity.x, velocity.z).length() > 0.5
		var target := "jump" if not is_on_floor() else ("run" if moving else "idle")
		if anim.current_animation != target:
			anim.play(target)


func _gain_special(amount: float) -> void:
	special = minf(SPECIAL_MAX, special + amount)


## Superpoder: onda de choque que derrota todos os bichos "na tela".
func _fire_special() -> void:
	special = 0.0
	stamina = STAMINA_MAX
	_iframes = maxf(_iframes, 1.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n != null and is_instance_valid(n) and n.has_method("super_hit") \
				and n.global_position.distance_to(global_position) < SPECIAL_RANGE:
			n.super_hit(global_position)
	Sfx.play("boss_roar", -2.0)
	Sfx.play("levelup", -2.0)
	_special_fx()


func _special_fx() -> void:
	var ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.25
	cyl.radial_segments = 32
	ring.mesh = cyl
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.9, 0.35, 0.8)
	ring.material_override = m
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.3, 0)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(SPECIAL_RANGE, 1, SPECIAL_RANGE), 0.5)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.5)
	tw.chain().tween_callback(ring.queue_free)
	var layer := CanvasLayer.new()
	layer.layer = 30
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 0.85, 0.85)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	get_tree().current_scene.add_child(layer)
	var tf := flash.create_tween()
	tf.tween_property(flash, "color:a", 0.0, 0.45)
	tf.tween_callback(layer.queue_free)


func _is_action_anim() -> bool:
	return anim.is_playing() and anim.current_animation in ["attack", "punch", "superpunch", "flykick"]


func _spend(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_regen_wait = REGEN_DELAY


func _start_attack(anim_name: String, cost: float, mult: float, active: float, cooldown: float) -> void:
	_spend(cost)
	_attack_cd = cooldown
	_attack_active = active
	_dmg_mult = mult
	_reveal = REVEAL_TIME
	sword.monitoring = true
	Sfx.play("hit", -8.0)
	if anim != null:
		anim.play(anim_name)


## Super soco (correndo) / voadora (correndo + pulo): avançam em disparada.
func _start_special(kind: String, cost: float, mult: float, duration: float, dash: float) -> void:
	_start_attack(kind, cost, mult, duration, duration + 0.3)
	_action = kind
	_action_t = duration
	_dash_vel = facing * dash
	sword.scale = Vector3(1.3, 1.2, 1.5)
	if kind == "flykick":
		velocity.y = maxf(velocity.y, 2.5)
	Sfx.play("boss_roar", -14.0)


func _nearest_enemy_dist() -> float:
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n != null and is_instance_valid(n):
			best = minf(best, n.global_position.distance_to(global_position))
	return best


## Rifle: mira no bicho mais perto na frente (senão atira reto) e dispara.
func _shoot() -> void:
	if _shot_cd > 0.0:
		return
	_shot_cd = SHOT_COOLDOWN
	_reveal = REVEAL_TIME
	var dir := facing
	var best_d := SHOT_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var to := n.global_position - global_position
		to.y = 0.0
		if to.length() < best_d and to.normalized().dot(facing) > 0.5:
			best_d = to.length()
			dir = to.normalized()
	facing = dir
	var b := BulletScene.instantiate()
	b.direction = dir
	b.damage = maxi(2, int(GameState.attack_damage() * 0.6))
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(0, 0.9, 0) + dir * 0.8
	Sfx.play("hit", -4.0)
	if anim != null:
		anim.play("attack")


func _attach_rifle() -> void:
	var arm := body.find_child("ArmR", true, false)
	if arm == null:
		return
	_rifle_attached = true
	var gun := Node3D.new()
	gun.name = "Rifle"
	gun.position = Vector3(0, -0.4, 0.05)
	arm.add_child(gun)
	CharacterBuilder.cap(gun, Vector3(0.09, 0.8, 0.09), Color(0.25, 0.27, 0.32), Vector3(0, 0, 0.4), true, "", Vector3(90, 0, 0))
	CharacterBuilder.cap(gun, Vector3(0.14, 0.3, 0.12), Color(0.55, 0.35, 0.2), Vector3(0, -0.02, -0.05), true, "", Vector3(90, 0, 0))
	CharacterBuilder.blob(gun, Vector3(0.1, 0.1, 0.18), Color(0.2, 0.8, 1.0), Vector3(0, 0.08, 0.3), false)


## Direção desejada: P1 = teclado/toque (ações); P2 = controle direto.
func _read_move() -> Vector2:
	if use_test_input:
		return test_move
	if player_id == 1:
		return _shape(Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")))
	var dev := GameState.joy_device()
	if dev < 0:
		return Vector2.ZERO
	var v := _shape(Vector2(Input.get_joy_axis(dev, JOY_AXIS_LEFT_X), Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y)))
	v.x += float(Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_LEFT))
	v.y += float(Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(dev, JOY_BUTTON_DPAD_UP))
	return v


## Zona morta radial: o analógico ao soltar "balança" e passa por valores
## pequenos; isso não pode mexer nem virar o personagem.
func _shape(v: Vector2) -> Vector2:
	var l := v.length()
	if l < DEADZONE:
		return Vector2.ZERO
	return v.normalized() * clampf((l - DEADZONE) / (1.0 - DEADZONE) + 0.2, 0.0, 1.0)


const PAD_BUTTONS := {
	"punch": [JOY_BUTTON_X], "kick": [JOY_BUTTON_Y], "jump": [JOY_BUTTON_A],
	"run": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER], "special": [JOY_BUTTON_LEFT_SHOULDER],
}


## Segurado agora? (P1: ações; P2: controle direto; simulação: test_pressed)
func _held(action: String) -> bool:
	if use_test_input:
		return test_pressed.get(action, false)
	if player_id == 1:
		return Input.is_action_pressed(action)
	var dev := GameState.joy_device()
	if dev < 0:
		return false
	for b in PAD_BUTTONS[action]:
		if Input.is_joy_button_pressed(dev, b):
			return true
	if action == "run":
		return Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_RIGHT) > 0.5
	return action == "special" and Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_LEFT) > 0.5


## Acabou de apertar? (consome na simulação)
func _just(action: String) -> bool:
	if use_test_input:
		if action == "punch" and test_attack:
			test_attack = false
			return true
		if action != "run" and test_pressed.get(action, false):
			test_pressed[action] = false
			return true
		return false
	if player_id == 1:
		return Input.is_action_just_pressed(action)
	var now := _held(action)
	var edge: bool = now and not _pad_prev.get(action, false)
	_pad_prev[action] = now
	return edge


## No co-op, quem tenta passar de LEASH metros do parceiro é segurado.
func _apply_leash() -> void:
	if not GameState.coop:
		return
	for other in get_tree().get_nodes_in_group("player"):
		if other == self or other.get("_dead") == true:
			continue
		var away: Vector3 = global_position - (other as Node3D).global_position
		away.y = 0.0
		if away.length() > LEASH:
			var dir := away.normalized()
			var out := velocity.dot(dir)
			if out > 0.0:
				velocity -= dir * out


func is_hidden() -> bool:
	return _bushes > 0 and _reveal <= 0.0 and not _dead


func bush_enter() -> void:
	_bushes += 1


func bush_exit() -> void:
	_bushes = maxi(0, _bushes - 1)


func _update_hidden_look() -> void:
	var hid := is_hidden()
	if hid == _hide_label.visible:
		return
	_hide_label.visible = hid
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		(mi as GeometryInstance3D).transparency = 0.55 if hid else 0.0


func _on_sword_hit(hit_body: Node) -> void:
	if hit_body.has_method("take_hit"):
		hit_body.take_hit(maxi(1, roundi(GameState.attack_damage() * _dmg_mult)), global_position)
		_gain_special(6.0 + 6.0 * _dmg_mult)  # soco +9,6 · chute +12 · especiais +16


func _process(delta: float) -> void:
	if rig == null:
		return
	var target := global_position
	var n := 1
	for other in get_tree().get_nodes_in_group("player"):  # câmera segue o meio da dupla
		if other != self and other.get("_dead") != true:
			target += (other as Node3D).global_position
			n += 1
	rig.global_position = rig.global_position.lerp(target / n, CAM_LERP * delta)


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


func kill() -> void:
	if not _dead:
		GameState.take_damage(GameState.max_hp)
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	body.visible = true
	if anim != null:
		anim.play("die")
	died.emit()
