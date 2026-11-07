extends Control
## Título: logo FMF, "Continuar" (se houver save) e "Nova aventura"
## (com confirmação se for apagar um save existente).

const PHASE_1 := "res://src/levels3d/phase_1.tscn"

var _confirming := false

@onready var continue_btn: Button = $Center/Box/Continue
@onready var new_btn: Button = $Center/Box/NewGame


func _ready() -> void:
	GameState.load_save()
	var has_save := not GameState.phases_done.is_empty() or GameState.coins > 0 \
		or GameState.level > 1 or GameState.xp > 0
	continue_btn.visible = has_save
	continue_btn.pressed.connect(_start)
	new_btn.pressed.connect(_on_new_game)
	if has_save:
		continue_btn.grab_focus()
	else:
		new_btn.grab_focus()


func _on_new_game() -> void:
	var has_save := continue_btn.visible
	if has_save and not _confirming:
		_confirming = true
		new_btn.text = "Apagar o save e recomeçar?"
		return
	GameState._apply_defaults()
	GameState.save()
	_start()


func _start() -> void:
	get_tree().change_scene_to_file(PHASE_1)
