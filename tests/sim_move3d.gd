extends SceneTree
## Movimento 3D: direita aumenta X; cima (move_up) diminui Z.
## Rodar: godot --headless --fixed-fps 60 --path . --script tests/sim_move3d.gd

var f := 0
var player: CharacterBody3D
var x0 := 0.0
var z0 := 0.0
var moved_x := false


func _initialize() -> void:
	change_scene_to_file("res://src/levels3d/arena_test.tscn")


func _process(_d) -> bool:
	f += 1
	if f == 10:
		player = current_scene.get_node("Player")
		x0 = player.global_position.x
		Input.action_press("move_right")
	if f == 70:
		Input.action_release("move_right")
		moved_x = player.global_position.x > x0 + 3.0
		z0 = player.global_position.z
		Input.action_press("move_up")
	if f == 130:
		Input.action_release("move_up")
		var moved_z := player.global_position.z < z0 - 3.0
		if moved_x and moved_z:
			print("MOVE3D PASSED")
			quit(0)
		else:
			print("FAIL moved_x=%s moved_z=%s" % [moved_x, moved_z])
			quit(1)
	return false
