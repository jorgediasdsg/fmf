extends Control
## Joystick virtual analógico (multi-touch): o primeiro dedo que tocar nesta
## área vira o joystick; injeta as ações move_* com força analógica.

const RADIUS := 42.0
const ACTIONS := {
	"move_right": Vector2.RIGHT,
	"move_left": Vector2.LEFT,
	"move_down": Vector2.DOWN,
	"move_up": Vector2.UP,
}

var _finger := -1
var _origin := Vector2.ZERO
var _vec := Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var pos := (event as InputEventScreenTouch).position
		if event.pressed and _finger == -1 and get_global_rect().has_point(pos):
			_finger = event.index
			_origin = pos
			_vec = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			_vec = Vector2.ZERO
			_apply()
			queue_redraw()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _finger:
		var drag := event as InputEventScreenDrag
		_vec = (drag.position - _origin) / RADIUS
		if _vec.length() > 1.0:
			_vec = _vec.normalized()
		_apply()
		queue_redraw()


func _apply() -> void:
	for action in ACTIONS:
		var strength := _vec.dot(ACTIONS[action])
		if strength > 0.12:
			Input.action_press(action, minf(strength, 1.0))
		else:
			Input.action_release(action)


func _draw() -> void:
	var center := (_origin - global_position) if _finger != -1 \
		else size * Vector2(0.5, 0.62)
	draw_circle(center, RADIUS, Color(0.1, 0.1, 0.18, 0.35))
	draw_arc(center, RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
	draw_circle(center + _vec * RADIUS * 0.7, 16.0, Color(1, 1, 1, 0.55))
