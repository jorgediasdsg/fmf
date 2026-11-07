extends CanvasLayer
## Controles de toque: joystick virtual à esquerda + botão de ataque à direita.
## Visível apenas em telas de toque; reposiciona ao redimensionar.

@onready var attack_btn: TouchScreenButton = $Attack


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var b := 56.0
	attack_btn.position = Vector2(s.x - b - 14.0, s.y - b - 14.0)
