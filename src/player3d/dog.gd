extends CharacterBody3D
## Cachorro do Zack: segue atrás dele; a cada cooldown, se houver inimigo
## perto, investe, morde (2 de dano) e volta.

@export var bite_damage := 2
@export var bite_cooldown := 2.5
@export var hunt_range := 7.0
@export var dash_speed := 12.0
@export var follow_speed := 7.0
@export var follow_distance := 1.5

enum State { FOLLOW, DASH, RETURN }

var _state := State.FOLLOW
var _cooldown := 0.0
var _target: Node3D
var model: Node3D
var anim: AnimationPlayer


func _ready() -> void:
	add_to_group("dog")
	model = CharacterBuilder.build_dog()
	add_child(model)
	anim = model.get_node("Anim")
	anim.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0
	_cooldown -= delta

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	match _state:
		State.FOLLOW:
			_follow(player, delta)
			if _cooldown <= 0.0:
				_target = _nearest_enemy()
				if _target != null:
					_state = State.DASH
					anim.play("attack")
		State.DASH:
			if _target == null or not is_instance_valid(_target):
				_state = State.RETURN
			else:
				var to_target := _target.global_position - global_position
				to_target.y = 0.0
				if to_target.length() < 0.7:
					if _target.has_method("take_hit"):
						_target.take_hit(bite_damage + GameState.dog_bite_bonus(), global_position)
					_cooldown = bite_cooldown
					_state = State.RETURN
				else:
					_move(to_target.normalized() * dash_speed, delta)
		State.RETURN:
			_follow(player, delta)
			if global_position.distance_to(player.global_position) < follow_distance + 0.6:
				_state = State.FOLLOW

	move_and_slide()
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	if anim.current_animation != "attack" or not anim.is_playing():
		var want := "run" if moving else "idle"
		if anim.current_animation != want:
			anim.play(want)


func _follow(player: Node3D, delta: float) -> void:
	var behind: Vector3 = player.global_position - player.get("facing") * follow_distance
	var to_spot := behind - global_position
	to_spot.y = 0.0
	if to_spot.length() > 0.4:
		_move(to_spot.normalized() * minf(follow_speed, to_spot.length() * 4.0), delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _move(vel: Vector3, delta: float) -> void:
	velocity.x = vel.x
	velocity.z = vel.z
	if vel.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(vel.x, vel.z), 10.0 * delta)


func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := hunt_range
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var d := global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best
