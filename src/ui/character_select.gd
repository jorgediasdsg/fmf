extends Control
## Escolha do herói: 3 cartões com o personagem girando; tocar/Enter no botão
## escolhe e começa a próxima fase. A escolha fica salva.

var _font := load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
var _step := 1  # co-op: 1 = jogador 1 (teclado), 2 = jogador 2 (controle)
var _title: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.12, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)
	_title = _label(_title_text(), 12)
	col.add_child(_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var focus_btn: Button = null
	for id in CharacterBuilder.HERO_ORDER:
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 6)
		row.add_child(card)
		card.add_child(_preview(id))
		var b := Button.new()
		b.text = CharacterBuilder.HERO_NAMES[id]
		b.custom_minimum_size = Vector2(138, 30)
		b.add_theme_font_override("font", _font)
		b.add_theme_font_size_override("font_size", 9)
		b.pressed.connect(_choose.bind(id))
		card.add_child(b)
		if id == GameState.character:
			focus_btn = b
	if focus_btn != null:
		focus_btn.grab_focus()


func _title_text() -> String:
	if not GameState.coop:
		return "Escolha seu herói"
	return "Jogador 1 (teclado): escolha" if _step == 1 else "Jogador 2 (controle): escolha"


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _preview(id: String) -> Control:
	var holder := SubViewportContainer.new()
	holder.custom_minimum_size = Vector2(138, 150)
	holder.stretch = true
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.34, 0.3)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.85, 0.82)
	e.ambient_light_energy = 0.9
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	vp.add_child(sun)
	var model := CharacterBuilder.build_hero(id)
	model.name = "Hero"
	vp.add_child(model)
	model.get_node("Anim").play("idle")
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.05, 3.6)
	cam.rotation_degrees = Vector3(-6, 0, 0)
	cam.fov = 38
	vp.add_child(cam)
	holder.set_meta("model", model)
	return holder


func _process(delta: float) -> void:
	for holder in find_children("*", "SubViewportContainer", true, false):
		var m: Node3D = holder.get_meta("model")
		m.rotation.y = sin(Time.get_ticks_msec() / 900.0) * 0.6


func _choose(id: String) -> void:
	if GameState.coop and _step == 1:
		GameState.set_character(id)
		_step = 2
		_title.text = _title_text()
		return
	if GameState.coop:
		GameState.set_character2(id)
	else:
		GameState.set_character(id)
	GameState.save()
	get_tree().change_scene_to_file(GameState.next_phase_path())
