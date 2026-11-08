extends CanvasLayer
## HUD: 5 corações (em terços), moedas, nível e barra de XP.
## Atualiza por sinais do GameState, nunca por polling.

const HEART_STATES := 4  # cheio, 2/3, 1/3, vazio

var _hearts: Array[TextureRect] = []
var _stamina_bars: Array = []  # [ProgressBar, player_id, StyleBoxFlat]
var _special_bars: Array = []

@onready var hearts_box: HBoxContainer = $Margin/Rows/Hearts
@onready var coin_label: Label = $Margin/Rows/CoinsRow/CoinLabel
@onready var level_label: Label = $Margin/Rows/LevelRow/LevelLabel
@onready var xp_bar: ProgressBar = $Margin/Rows/LevelRow/XpBar


func _ready() -> void:
	var tex := load("res://assets/sprites/hearts.png") as Texture2D
	for i in range(5):
		var tr := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, 0, 8, 8)
		tr.texture = at
		tr.custom_minimum_size = Vector2(20, 20)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hearts_box.add_child(tr)
		_hearts.append(tr)
	_make_stamina_row()
	GameState.hp_changed.connect(_on_hp)
	GameState.coins_changed.connect(_on_coins)
	GameState.xp_changed.connect(_on_xp)
	GameState.leveled_up.connect(_on_level)
	_on_hp(GameState.hp, GameState.max_hp)
	_on_coins(GameState.coins)
	_on_xp(GameState.xp, GameState.xp_to_next())
	_on_level(GameState.level)


## Barra de força: cai com golpes/corrida, volta parado, fica estável andando.
func _make_stamina_row() -> void:
	var rows := hearts_box.get_parent()
	var font := load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
	for pid in ([1, 2] if GameState.coop else [1]):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var lbl := Label.new()
		lbl.text = "Força"
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.1))
		lbl.add_theme_constant_override("outline_size", 3)
		row.add_child(lbl)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(70, 8)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.max_value = 100.0
		bar.value = 100.0
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.3, 0.75, 1.0)
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("fill", fill)
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0.07, 0.06, 0.1, 0.7)
		back.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", back)
		row.add_child(bar)
		rows.add_child(row)
		_stamina_bars.append([bar, pid, fill])
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 6)
		var slbl := Label.new()
		slbl.text = "Esp."
		slbl.add_theme_font_override("font", font)
		slbl.add_theme_font_size_override("font_size", 8)
		slbl.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.1))
		slbl.add_theme_constant_override("outline_size", 3)
		srow.add_child(slbl)
		var sbar := ProgressBar.new()
		sbar.custom_minimum_size = Vector2(70, 8)
		sbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sbar.show_percentage = false
		sbar.max_value = 100.0
		var sfill := StyleBoxFlat.new()
		sfill.bg_color = Color(0.8, 0.4, 1.0)
		sfill.set_corner_radius_all(3)
		sbar.add_theme_stylebox_override("fill", sfill)
		sbar.add_theme_stylebox_override("background", back)
		srow.add_child(sbar)
		rows.add_child(srow)
		_special_bars.append([sbar, pid, sfill])


func _process(_delta: float) -> void:
	for entry in _stamina_bars:
		var who: Node = null
		for p in get_tree().get_nodes_in_group("player"):
			if p.get("player_id") == entry[1]:
				who = p
		if who == null:
			continue
		var v: float = who.stamina
		(entry[0] as ProgressBar).value = v
		(entry[2] as StyleBoxFlat).bg_color = Color(0.3, 0.75, 1.0) if v > 30.0 else Color(1.0, 0.45, 0.3)
	for entry in _special_bars:
		for p in get_tree().get_nodes_in_group("player"):
			if p.get("player_id") == entry[1]:
				var sv: float = p.special
				(entry[0] as ProgressBar).value = sv
				var full := sv >= 100.0  # cheia: pisca dourado
				(entry[2] as StyleBoxFlat).bg_color = Color(1.0, 0.85, 0.2) if full and int(Time.get_ticks_msec() / 150) % 2 == 0 else Color(0.8, 0.4, 1.0)


func _on_hp(hp: int, _max_hp: int) -> void:
	for i in range(5):
		var thirds := clampi(hp - i * 3, 0, 3)
		var state := 3 - thirds  # 3 terços → frame 0 (cheio) ... 0 → frame 3 (vazio)
		(_hearts[i].texture as AtlasTexture).region = Rect2(state * 8, 0, 8, 8)


func _on_coins(coins: int) -> void:
	coin_label.text = str(coins)


func _on_xp(xp: int, to_next: int) -> void:
	xp_bar.max_value = to_next
	xp_bar.value = xp


func _on_level(level: int) -> void:
	level_label.text = "Nv. %d" % level
	_on_xp(GameState.xp, GameState.xp_to_next())
