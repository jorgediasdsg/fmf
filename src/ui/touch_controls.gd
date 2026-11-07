extends CanvasLayer
## Controles de toque: visíveis só em telas touch; reposiciona ao redimensionar.

@onready var left: TouchScreenButton = $Left
@onready var right: TouchScreenButton = $Right
@onready var jump: TouchScreenButton = $Jump
@onready var attack: TouchScreenButton = $Attack


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var b := 48.0  # tamanho do botão em pixels do canvas (64 * 0.75)
	var margin := 10.0
	left.position = Vector2(margin, s.y - b - margin)
	right.position = Vector2(margin + b + 8.0, s.y - b - margin)
	attack.position = Vector2(s.x - 2.0 * b - margin - 8.0, s.y - b - margin)
	jump.position = Vector2(s.x - b - margin, s.y - b - margin - 14.0)
