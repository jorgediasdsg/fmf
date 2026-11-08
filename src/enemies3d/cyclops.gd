extends CharacterBody3D
## Ciclope 3D: vagueia; persegue o player a <8 m; dano por contato;
## morre soltando moedas e XP. O chefe reusa via exports/herança.

signal defeated

@export var hp := 10
@export var contact_damage := 2
@export var speed := 2.5
@export var xp_reward := 5
@export var coin_min := 1
@export var coin_max := 2
@export var chase_range := 8.0
@export var contact_range := 1.0
@export var boss := false
@export var fixed_hits := 0  # >0: morre com exatamente esse nº de golpes (qualquer dano)

const CoinScene := preload("res://src/items3d/coin.tscn")
const FoodScene := preload("res://src/items3d/food.tscn")

@export var food_chance := 0.12  # só de vez em quando, na sorte

const ALLY_RADIUS := 14.0   # bichos assim tão perto vêm ajudar
const ALERT_TIME := 6.0
const ALERT_CHASE := 26.0   # alertado, persegue de bem longe

var max_hp := 1
var _alert := 0.0
var _call_t := 0.0
var _bar_fill: MeshInstance3D
var _bar_w := 0.9

var _wander_dir := Vector3.ZERO
var _wander_t := 0.0
var _dying := false
var model: Node3D
var anim: AnimationPlayer


func _ready() -> void:
	add_to_group("enemies")
	if boss:
		add_to_group("boss")
	model = _make_model()
	add_child(model)
	anim = model.get_node("Anim")
	anim.play("idle")
	if fixed_hits > 0:
		hp = fixed_hits
	max_hp = maxi(1, hp)
	_make_hp_bar()


## Barrinha de vida flutuando sobre o bicho; desce quando ele apanha.
func _make_hp_bar() -> void:
	_bar_w = 1.7 if boss else 0.9
	var bar := Node3D.new()
	bar.name = "HpBar"
	bar.position.y = 1.55 * _base_scale() + 0.35
	add_child(bar)
	var bg := MeshInstance3D.new()
	var qb := QuadMesh.new()
	qb.size = Vector2(_bar_w + 0.1, 0.22)
	bg.mesh = qb
	bg.material_override = _bar_material(Color(0.07, 0.06, 0.1), 0)
	bar.add_child(bg)
	_bar_fill = MeshInstance3D.new()
	var qf := QuadMesh.new()
	qf.size = Vector2(_bar_w, 0.14)
	qf.center_offset = Vector3(_bar_w / 2.0, 0, 0)
	_bar_fill.mesh = qf
	_bar_fill.position = Vector3(-_bar_w / 2.0, 0, 0.01)
	_bar_fill.material_override = _bar_material(Color(0.3, 0.9, 0.3), 1)
	bar.add_child(_bar_fill)


func _bar_material(color: Color, prio: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = prio
	m.albedo_color = color
	return m


func _update_hp_bar() -> void:
	if _bar_fill == null:
		return
	var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_bar_fill.scale.x = maxf(frac, 0.001)
	var col := Color(0.3, 0.9, 0.3) if frac > 0.5 else (Color(1.0, 0.85, 0.2) if frac > 0.25 else Color(0.95, 0.25, 0.25))
	(_bar_fill.material_override as StandardMaterial3D).albedo_color = col
	if hp <= 0:
		get_node("HpBar").visible = false


func _base_scale() -> float:
	return 2.2 if boss else 1.0


func _make_model() -> Node3D:
	return CharacterBuilder.build_cyclops(_base_scale(), boss)


## Um aliado pediu ajuda: passa um tempo perseguindo de longe.
func alert() -> void:
	_alert = ALERT_TIME


func _chase_limit() -> float:
	return ALERT_CHASE if _alert > 0.0 else chase_range


func _call_allies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and is_instance_valid(e) and e.has_method("alert") \
				and (e as Node3D).global_position.distance_to(global_position) < ALLY_RADIUS:
			e.alert()


## Jogador visível mais perto (escondido na moita não conta).
func _target() -> Node3D:
	return GameState.nearest_player(global_position, true)


## O herói escondido no mato não é visto (nem perseguido).
func _can_see(player: Node3D) -> bool:
	return player != null and not (player.has_method("is_hidden") and player.is_hidden())


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
	if _can_see(player) and (player.global_position - global_position).length() < _chase_limit():
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() < contact_range and player.has_method("hurt"):
			player.hurt(contact_damage, global_position)
		dir = to_player.normalized()
		if _call_t <= 0.0 and to_player.length() < chase_range:
			_call_t = 1.0
			_call_allies()
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


## Superpoder do herói: mata os comuns; o chefe só perde uma boa parte da vida.
func super_hit(from_pos: Vector3) -> void:
	if _dying:
		return
	if boss:
		if fixed_hits > 0:
			take_hit(1, from_pos)
			take_hit(1, from_pos)
		else:
			take_hit(maxi(1, int(max_hp * 0.25)), from_pos)
	else:
		hp = 1
		take_hit(1, from_pos)


func take_hit(damage: int, from_pos: Vector3) -> void:
	if _dying:
		return
	hp -= 1 if fixed_hits > 0 else damage
	_update_hp_bar()
	alert()
	_call_allies()
	var push := global_position - from_pos
	push.y = 0.0
	if push.length() > 0.01:
		velocity += push.normalized() * 5.0
	_punch_scale()
	Sfx.play("hit", -4.0)
	if hp <= 0:
		_die()


func _punch_scale() -> void:
	var base := Vector3.ONE * _base_scale()
	model.scale = base * 1.18
	var tw := create_tween()
	tw.tween_property(model, "scale", base, 0.12)


func _die() -> void:
	_dying = true
	# Créditos ANTES de defeated.emit(): a vitória salva o jogo em resposta
	# ao sinal, e o XP/moedas do chefe precisam estar dentro desse save.
	GameState.add_xp(xp_reward)
	var parent := get_parent()
	var rng := RandomNumberGenerator.new()
	var n_coins := rng.randi_range(coin_min, coin_max)
	if boss:
		# a árvore pausa na vitória; moedas no chão seriam incoletáveis
		GameState.add_coins(n_coins)
	else:
		for i in range(n_coins):
			var coin := CoinScene.instantiate()
			coin.position = global_position + Vector3(rng.randf_range(-0.7, 0.7), 0.4,
				rng.randf_range(-0.7, 0.7))
			parent.call_deferred("add_child", coin)
	if not boss and rng.randf() < food_chance:
		var food := FoodScene.instantiate()
		food.position = global_position + Vector3(rng.randf_range(-0.5, 0.5), 0.3,
			rng.randf_range(-0.5, 0.5))
		parent.call_deferred("add_child", food)
	_puff(parent)
	defeated.emit()
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
