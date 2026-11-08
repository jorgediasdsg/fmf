extends Control
## Título: logo FMF, "Continuar" (se houver save) e "Nova aventura"
## (com confirmação se for apagar um save existente).

const SELECT_SCENE := "res://src/ui/character_select.tscn"

var _confirming := false

@onready var continue_btn: Button = $Center/Box/Continue
@onready var new_btn: Button = $Center/Box/NewGame


func _ready() -> void:
	GameState.load_save()
	var has_save := not GameState.phases_done.is_empty() or GameState.coins > 0 \
		or GameState.level > 1 or GameState.xp > 0
	continue_btn.visible = has_save
	GameState.coop = false
	GameState.apply_input_mode()
	var players_btn := Button.new()
	players_btn.add_theme_font_override("font", new_btn.get_theme_font("font"))
	players_btn.add_theme_font_size_override("font_size", 10)
	players_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	players_btn.text = "Jogadores: 1"
	players_btn.pressed.connect(func():
		GameState.coop = not GameState.coop
		players_btn.text = "Jogadores: 2 (teclado + controle)" if GameState.coop else "Jogadores: 1")
	new_btn.get_parent().add_child(players_btn)
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
	get_tree().change_scene_to_file(SELECT_SCENE)

