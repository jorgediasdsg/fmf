extends CanvasLayer
## HUD: 5 corações (em terços), moedas, nível e barra de XP.
## Atualiza por sinais do GameState, nunca por polling.

const HEART_STATES := 4  # cheio, 2/3, 1/3, vazio

var _hearts: Array[TextureRect] = []

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
	GameState.hp_changed.connect(_on_hp)
	GameState.coins_changed.connect(_on_coins)
	GameState.xp_changed.connect(_on_xp)
	GameState.leveled_up.connect(_on_level)
	_on_hp(GameState.hp, GameState.max_hp)
	_on_coins(GameState.coins)
	_on_xp(GameState.xp, GameState.xp_to_next())
	_on_level(GameState.level)


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
