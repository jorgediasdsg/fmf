class_name BushPatch
extends Node3D
## Moita alta: quem entra nela (o Zack) fica escondido e os bichos não o veem.
## O Zack conta quantas moitas o cobrem, assim moitas coladas não o "revelam".

const RADIUS := 1.7

var greens: Array = [Color(0.18, 0.72, 0.3), Color(0.25, 0.8, 0.35), Color(0.14, 0.6, 0.28)]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 31 + position.z * 17)
	for i in range(9):
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.2, RADIUS - 0.5)
		var h := rng.randf_range(1.2, 1.7)
		CharacterBuilder.blob(self, Vector3(1.1, h, 1.1), greens[i % 3],
			Vector3(cos(a) * r, h / 2.0 - 0.1, sin(a) * r))
	for mi in find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).visibility_range_end = 32.0 if GameState.low_end else 50.0
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = RADIUS - 0.3
	sh.height = 2.0
	cs.shape = sh
	cs.position.y = 1.0
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(b): if b.has_method("bush_enter"): b.bush_enter())
	area.body_exited.connect(func(b): if b.has_method("bush_exit"): b.bush_exit())
