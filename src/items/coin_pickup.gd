extends Area2D
## Moeda: gira, bóia, tem ímã leve até o jogador e soma 1 ao coletar.

const MAGNET_RADIUS := 48.0
const MAGNET_SPEED := 120.0

var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) < MAGNET_RADIUS:
		global_position = global_position.move_toward(
			player.global_position + Vector2(0, -10), MAGNET_SPEED * delta)
		_base_y = position.y
	else:
		position.y = _base_y + sin(_t * 4.0) * 2.0


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_coins(1)
		Sfx.play("coin", -6.0)
		queue_free()
