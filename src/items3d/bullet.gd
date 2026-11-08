extends Area3D
## Tiro do rifle: voa reto, acerta o primeiro bicho (1 golpe) ou some na parede.

const SPEED := 24.0
const LIFETIME := 0.75   # ~18 m de alcance

var direction := Vector3.FORWARD
var damage := 3
var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body)
	CharacterBuilder.blob(self, Vector3(0.22, 0.22, 0.4), Color(1.0, 0.9, 0.3), Vector3.ZERO, false)
	CharacterBuilder.blob(self, Vector3(0.3, 0.3, 0.5), Color(1.0, 0.7, 0.2, 1.0), Vector3.ZERO)


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(damage, global_position - direction)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
