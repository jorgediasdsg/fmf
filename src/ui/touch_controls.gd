extends CanvasLayer
## Controles de toque: joystick virtual à esquerda + 4 botões à direita
## (soco, chute, pular, correr-segurando). Só em telas de toque.

@onready var punch_btn: TouchScreenButton = $Punch
@onready var kick_btn: TouchScreenButton = $Kick
@onready var jump_btn: TouchScreenButton = $Jump
@onready var run_btn: TouchScreenButton = $Run
@onready var special_btn: TouchScreenButton = $Special


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var b := 56.0
	var m := 12.0
	var right := s.x - b - m
	var left := right - b - 8.0
	var low := s.y - b - m
	var high := low - b - 8.0
	punch_btn.position = Vector2(right, low)
	kick_btn.position = Vector2(left, low)
	jump_btn.position = Vector2(right, high)
	run_btn.position = Vector2(left, high)
	special_btn.position = Vector2((left + right) / 2.0, high - b - 8.0)


func _process(_delta: float) -> void:
	# botão de especial só "acende" quando a barra está cheia
	for p in get_tree().get_nodes_in_group("player"):
		if p.get("player_id") == 1:
			special_btn.modulate.a = 1.0 if p.special >= 100.0 else 0.3
