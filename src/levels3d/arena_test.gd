extends Node3D
## Arena de teste 3D: chão, paredes invisíveis, árvores e pedras em código.

const GROUND_SIZE := Vector3(40, 1, 20)


func _ready() -> void:
	_ground()
	_walls()
	for pos in [Vector3(-14, 0, -6), Vector3(-8, 0, 5), Vector3(6, 0, -7),
			Vector3(13, 0, 4), Vector3(17, 0, -3)]:
		add_child(_tree(pos))
	for pos in [Vector3(-3, 0, 2), Vector3(9, 0, 6), Vector3(-16, 0, 3)]:
		add_child(_rock(pos))


func _ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = GROUND_SIZE
	mesh.mesh = box
	mesh.material_override = ToonMaterial.flat(Color(0.32, 0.5, 0.29), 0.15)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = GROUND_SIZE
	col.shape = shape
	body.add_child(mesh)
	body.add_child(col)
	body.position = Vector3(0, -0.5, 0)
	add_child(body)


func _walls() -> void:
	var half_x := GROUND_SIZE.x / 2.0
	var half_z := GROUND_SIZE.z / 2.0
	for data in [[Vector3(0, 2, -half_z - 0.5), Vector3(GROUND_SIZE.x, 4, 1)],
			[Vector3(0, 2, half_z + 0.5), Vector3(GROUND_SIZE.x, 4, 1)],
			[Vector3(-half_x - 0.5, 2, 0), Vector3(1, 4, GROUND_SIZE.z)],
			[Vector3(half_x + 0.5, 2, 0), Vector3(1, 4, GROUND_SIZE.z)]]:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = data[1]
		col.shape = shape
		body.add_child(col)
		body.position = data[0]
		add_child(body)


func _tree(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var trunk := MeshInstance3D.new()
	var tmesh := CylinderMesh.new()
	tmesh.top_radius = 0.22
	tmesh.bottom_radius = 0.3
	tmesh.height = 1.4
	trunk.mesh = tmesh
	trunk.position.y = 0.7
	trunk.material_override = ToonMaterial.flat(Color(0.42, 0.29, 0.19), 0.2)
	ToonMaterial.add_outline(trunk, 0.04)
	root.add_child(trunk)
	var leaves := MeshInstance3D.new()
	var lmesh := CylinderMesh.new()
	lmesh.top_radius = 0.0
	lmesh.bottom_radius = 1.3
	lmesh.height = 2.8
	leaves.mesh = lmesh
	leaves.position.y = 2.6
	leaves.material_override = ToonMaterial.flat(Color(0.16, 0.38, 0.22), 0.3)
	ToonMaterial.add_outline(leaves, 0.05)
	root.add_child(leaves)
	return root


func _rock(pos: Vector3) -> Node3D:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 0.7
	rock.mesh = mesh
	rock.position = pos
	rock.material_override = ToonMaterial.flat(Color(0.45, 0.44, 0.5), 0.2)
	ToonMaterial.add_outline(rock, 0.04)
	return rock
