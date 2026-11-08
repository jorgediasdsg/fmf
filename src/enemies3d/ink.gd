extends Area3D
## Bola de tinta do polvo: voa reto, machuca o Zack ao tocar e some ao
## bater em parede/chão ou depois de alguns segundos.

const LIFETIME := 3.0

var direction := Vector3.FORWARD
var speed := 7.0
var damage := 2
var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body)
	CharacterBuilder.blob(self, Vector3(0.45, 0.45, 0.45), Color(0.28, 0.14, 0.45), Vector3.ZERO)
	CharacterBuilder.blob(self, Vector3(0.12, 0.12, 0.12), Color(0.8, 0.7, 1.0), Vector3(0.08, 0.1, 0.1), false)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("hurt"):
			body.hurt(damage, global_position - direction)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
