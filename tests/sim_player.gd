extends SceneTree
var f := 0
var p: CharacterBody2D
var x0 := 0.0
var y_min := 1e9
var moved_ok := false
var jumped_ok := false
var attack_ok := false
func _initialize() -> void:
	change_scene_to_file("res://src/levels/test_level.tscn")
func _process(_d) -> bool:
	f += 1
	if f == 10:
		p = current_scene.get_node("Player")
		x0 = p.global_position.x
		Input.action_press("move_right")
	if f > 10 and f <= 40 and p:
		y_min = min(y_min, p.global_position.y)
	if f == 40:
		Input.action_release("move_right")
		moved_ok = p.global_position.x > x0 + 30.0
		Input.action_press("jump")
	if f == 42:
		Input.action_release("jump")
	if f > 40 and f < 80:
		y_min = min(y_min, p.global_position.y)
	if f == 80:
		jumped_ok = y_min < 100.0  # chão fica em y=128
		Input.action_press("attack")
	if f == 82:
		attack_ok = p.get_node("SwordHitbox").monitoring
		Input.action_release("attack")
	if f == 90:
		print("moved=%s jumped=%s attack=%s" % [moved_ok, jumped_ok, attack_ok])
		quit(0 if (moved_ok and jumped_ok and attack_ok) else 1)
	return false
