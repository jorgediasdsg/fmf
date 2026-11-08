extends Area3D
## Árvore arremessada pelo Gorila Rei: voa reta rente ao chão. Quem for
## atingido perde metade da vida; dá para desviar de lado ou PULAR por cima.

const SPEED := 11.0
const LIFETIME := 2.4

var direction := Vector3.FORWARD
var _age := 0.0
var _hit := false


func _ready() -> void:
	add_to_group("tree_missile")
	body_entered.connect(_on_body)
	var visual := Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	CharacterBuilder.build_tree_missile(visual)
	visual.rotation.y = atan2(direction.x, direction.z)


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		if not _hit and body.has_method("hurt"):
			_hit = true
			body.hurt(ceili(GameState.max_hp / 2.0), global_position - direction)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
