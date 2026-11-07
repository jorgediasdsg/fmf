extends Area3D
## Moeda 3D: gira, tem ímã até o player e soma 1 ao coletar.

const MAGNET_RADIUS := 3.0
const MAGNET_SPEED := 7.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.18
	cyl.height = 0.06
	mesh.mesh = cyl
	mesh.rotation_degrees.x = 90.0
	mesh.position.y = 0.3
	mesh.material_override = ToonMaterial.flat(Color(0.95, 0.8, 0.3), 0.9)
	ToonMaterial.add_outline(mesh, 0.015)
	add_child(mesh)


func _physics_process(delta: float) -> void:
	rotate_y(3.0 * delta)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		var d := global_position.distance_to(player.global_position)
		if d < MAGNET_RADIUS:
			global_position = global_position.move_toward(
				player.global_position + Vector3(0, 0.5, 0), MAGNET_SPEED * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_coins(1)
		Sfx.play("coin", -6.0)
		queue_free()
