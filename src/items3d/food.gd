extends Area3D
## Comida solta pelos inimigos: maçã que cura 1 coração. Só é pega (e só
## atrai) quando a vida não está cheia; some sozinha depois de um tempo.

const MAGNET_RADIUS := 3.0
const MAGNET_SPEED := 7.0
const LIFETIME := 25.0

var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var apple := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.38
	apple.mesh = sphere
	apple.position.y = 0.35
	apple.material_override = ToonMaterial.flat(Color(0.88, 0.14, 0.16), 0.9)
	ToonMaterial.add_outline(apple, 0.02)
	add_child(apple)
	var leaf := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.14, 0.03, 0.08)
	leaf.mesh = lm
	leaf.position = Vector3(0.05, 0.57, 0)
	leaf.rotation_degrees.z = 20.0
	leaf.material_override = ToonMaterial.flat(Color(0.3, 0.7, 0.25), 0.9)
	add_child(leaf)


func _physics_process(delta: float) -> void:
	rotate_y(2.0 * delta)
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	if GameState.hp >= GameState.max_hp:
		return
	var player := GameState.nearest_player(global_position)
	if player != null and global_position.distance_to(player.global_position) < MAGNET_RADIUS:
		global_position = global_position.move_toward(
			player.global_position + Vector3(0, 0.5, 0), MAGNET_SPEED * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and GameState.hp < GameState.max_hp:
		GameState.heal(GameState.FOOD_HEAL)
		Sfx.play("levelup", -8.0)
		queue_free()
