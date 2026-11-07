extends CanvasLayer
## Tela de sobreposição (vitória/derrota): título, texto e um botão.

signal action

@onready var title_label: Label = $Panel/Center/Box/Title
@onready var info_label: Label = $Panel/Center/Box/Info
@onready var button: Button = $Panel/Center/Box/Action


func _ready() -> void:
	visible = false
	button.pressed.connect(func(): action.emit())


func open(title: String, info: String, button_text: String) -> void:
	title_label.text = title
	info_label.text = info
	button.text = button_text
	visible = true
	button.grab_focus()
