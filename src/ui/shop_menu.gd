class_name ShopMenu
extends CanvasLayer
## Bazar do Gato: balcão de madeira com toldo e prateleira de cartões com
## ícones. Pausa o jogo. Navegação por controle (direcional/analógico = mover,
## A = comprar, B = sair), teclado, mouse e toque.

signal closed

const CREAM := Color(0.98, 0.93, 0.78)
const WOOD := Color(0.55, 0.35, 0.2)
const WOOD_DARK := Color(0.33, 0.2, 0.12)
const GOLD := Color(1.0, 0.8, 0.25)

var _font := load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
var _coins_label: Label
var _msg_label: Label
var _cards := {}      # id -> {btn, price, icon}
var _close_btn: Button


## Ícones desenhados em código (nada de imagem externa).
class ShopArt extends Control:
	var kind := ""

	func _init(k := "", s := Vector2(36, 36)) -> void:
		kind = k
		custom_minimum_size = s
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _o(c: Color) -> Color:
		return c.darkened(0.55)

	func _disc(p: Vector2, r: float, c: Color) -> void:
		draw_circle(p, r + 1.5, _o(c))
		draw_circle(p, r, c)

	func _box(rc: Rect2, c: Color) -> void:
		draw_rect(rc.grow(1.5), _o(c))
		draw_rect(rc, c)

	func _draw() -> void:
		var u := 1.0 if kind == "awning" else size.x / 36.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(u, u))
		match kind:
			"apple":
				_disc(Vector2(18, 21), 11, Color(0.9, 0.15, 0.18))
				draw_colored_polygon(PackedVector2Array([Vector2(18, 10), Vector2(26, 4), Vector2(24, 12)]), Color(0.25, 0.7, 0.25))
				draw_line(Vector2(18, 11), Vector2(18, 6), Color(0.4, 0.25, 0.15), 2.0)
				draw_circle(Vector2(13, 17), 2.0, Color(1, 1, 1, 0.55))
			"cake":
				_box(Rect2(5, 22, 26, 9), Color(0.6, 0.35, 0.2))
				_box(Rect2(7, 15, 22, 8), Color(1.0, 0.95, 0.8))
				_box(Rect2(9, 9, 18, 7), Color(1.0, 0.55, 0.7))
				_disc(Vector2(18, 7), 3, Color(0.9, 0.1, 0.15))
			"magazine":
				_box(Rect2(8, 4, 21, 29), Color(0.25, 0.5, 0.95))
				draw_rect(Rect2(11, 7, 15, 6), GOLD)
				draw_rect(Rect2(11, 16, 15, 2), Color(1, 1, 1, 0.85))
				draw_rect(Rect2(11, 20, 11, 2), Color(1, 1, 1, 0.85))
				draw_circle(Vector2(19, 27), 3.0, Color(1, 0.85, 0.3))
			"dog_food":
				draw_colored_polygon(PackedVector2Array([Vector2(7, 8), Vector2(29, 8), Vector2(31, 33), Vector2(5, 33)]), _o(Color(0.8, 0.5, 0.25)))
				draw_colored_polygon(PackedVector2Array([Vector2(9, 10), Vector2(27, 10), Vector2(29, 31), Vector2(7, 31)]), Color(0.8, 0.5, 0.25))
				draw_rect(Rect2(7, 5, 22, 5), Color(0.95, 0.85, 0.6))
				draw_rect(Rect2(12, 19, 12, 4), Color.WHITE)
				draw_circle(Vector2(12, 19), 2.5, Color.WHITE)
				draw_circle(Vector2(12, 23), 2.5, Color.WHITE)
				draw_circle(Vector2(24, 19), 2.5, Color.WHITE)
				draw_circle(Vector2(24, 23), 2.5, Color.WHITE)
				draw_circle(Vector2(18, 13), 2.0, GOLD)
			"rifle":
				_box(Rect2(3, 14, 28, 5), Color(0.3, 0.32, 0.38))
				draw_colored_polygon(PackedVector2Array([Vector2(26, 13), Vector2(34, 16), Vector2(34, 24), Vector2(24, 20)]), Color(0.55, 0.35, 0.2))
				_box(Rect2(11, 19, 4, 8), Color(0.3, 0.32, 0.38))
				_disc(Vector2(16, 11), 2.5, Color(0.3, 0.8, 1.0))
			"cat":
				_disc(Vector2(18, 21), 13, Color(0.98, 0.62, 0.22))
				draw_colored_polygon(PackedVector2Array([Vector2(7, 14), Vector2(8, 3), Vector2(16, 10)]), Color(0.98, 0.62, 0.22))
				draw_colored_polygon(PackedVector2Array([Vector2(29, 14), Vector2(28, 3), Vector2(20, 10)]), Color(0.98, 0.62, 0.22))
				draw_circle(Vector2(13, 19), 2.2, Color(0.15, 0.13, 0.2))
				draw_circle(Vector2(23, 19), 2.2, Color(0.15, 0.13, 0.2))
				draw_circle(Vector2(18, 24), 1.6, Color(1.0, 0.55, 0.6))
				draw_line(Vector2(8, 23), Vector2(2, 22), Color.WHITE, 1.2)
				draw_line(Vector2(28, 23), Vector2(34, 22), Color.WHITE, 1.2)
			"coin":
				_disc(Vector2(18, 18), 11, GOLD)
				draw_circle(Vector2(18, 18), 6.0, GOLD.lightened(0.25))
			"awning":
				var w := size.x / u
				var n := 14
				var sw := w / n
				for i in range(n):
					var c := Color(0.95, 0.2, 0.22) if i % 2 == 0 else Color(1.0, 0.97, 0.9)
					draw_rect(Rect2(i * sw, 0, sw + 0.6, 14), c)
					draw_circle(Vector2(i * sw + sw / 2.0, 14), sw / 2.0, c)


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WOOD, WOOD_DARK, 3, 8, 6))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	col.add_child(ShopArt.new("awning", Vector2(430, 22)))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	head.add_child(ShopArt.new("cat", Vector2(30, 30)))
	head.add_child(_label("Bazar do Gato", 12, Color.WHITE, true))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	head.add_child(ShopArt.new("coin", Vector2(20, 20)))
	_coins_label = _label("0", 10, GOLD, false)
	head.add_child(_coins_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	for id in GameState.SHOP_ORDER:
		grid.add_child(_make_card(id))
	_close_btn = Button.new()
	_close_btn.text = "Sair  (B)"
	_close_btn.custom_minimum_size = Vector2(136, 58)
	_style_button(_close_btn, Color(0.85, 0.75, 0.6))
	_close_btn.add_theme_font_override("font", _font)
	_close_btn.add_theme_font_size_override("font_size", 9)
	_close_btn.add_theme_color_override("font_color", WOOD_DARK)
	_close_btn.add_theme_color_override("font_focus_color", WOOD_DARK)
	_close_btn.add_theme_color_override("font_hover_color", WOOD_DARK)
	_close_btn.pressed.connect(close)
	grid.add_child(_close_btn)
	_msg_label = _label("", 7, Color(1, 0.95, 0.8), true)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_msg_label)


func _style(bg: Color, border: Color, bw := 2, radius := 6, margin := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _style_button(b: Button, bg: Color) -> void:
	b.add_theme_stylebox_override("normal", _style(bg, WOOD_DARK))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.1), GOLD))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.12), GOLD))
	b.add_theme_stylebox_override("focus", _style(bg.lightened(0.15), GOLD, 4))
	b.add_theme_stylebox_override("disabled", _style(bg.darkened(0.25), WOOD_DARK.lightened(0.15)))


func _label(text: String, size: int, color: Color, outline: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.1))
		l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _make_card(id: String) -> Button:
	var info: Dictionary = GameState.SHOP_ITEMS[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(136, 58)
	_style_button(b, CREAM)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 5
	row.offset_right = -4
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var icon := ShopArt.new(id, Vector2(34, 34))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.pivot_offset = Vector2(17, 17)
	row.add_child(icon)
	var txt := VBoxContainer.new()
	txt.add_theme_constant_override("separation", 1)
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(txt)
	var name_l := _label(info.name, 7, WOOD_DARK, false)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size.x = 80
	txt.add_child(name_l)
	var desc := _label(info.desc, 6, Color(0.45, 0.35, 0.28), false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 80
	txt.add_child(desc)
	var price := _label("", 8, Color(0.1, 0.5, 0.15), false)
	txt.add_child(price)
	b.pressed.connect(_on_buy.bind(id))
	_cards[id] = {"btn": b, "price": price, "icon": icon}
	return b


func _unhandled_input(event: InputEvent) -> void:
	# B / Esc fecha a loja (controle ou teclado)
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	if visible:
		return
	_msg_label.text = "Direcional move · A compra · B sai"
	_refresh()
	visible = true
	get_tree().paused = true
	_focus_first()


func _focus_first() -> void:
	for id in GameState.SHOP_ORDER:
		var b: Button = _cards[id].btn
		if not b.disabled:
			b.grab_focus()
			return
	_close_btn.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


func _refresh() -> void:
	_coins_label.text = str(GameState.coins)
	for id in GameState.SHOP_ORDER:
		var info: Dictionary = GameState.SHOP_ITEMS[id]
		var card: Dictionary = _cards[id]
		var b: Button = card.btn
		var price: Label = card.price
		if id == "rifle" and GameState.has_rifle:
			price.text = "Comprado!"
			price.add_theme_color_override("font_color", Color(0.1, 0.5, 0.15))
		elif not GameState.is_unlocked(id):
			price.text = "Fase %d+" % int(info.min_phase)
			price.add_theme_color_override("font_color", Color(0.5, 0.4, 0.35))
		else:
			price.text = "$ %d" % GameState.price_of(id)
			var ok := GameState.coins >= GameState.price_of(id)
			price.add_theme_color_override("font_color", Color(0.1, 0.5, 0.15) if ok else Color(0.8, 0.15, 0.15))
		b.disabled = not GameState.can_buy(id)


const BUY_MESSAGES := {
	"apple": "Nham! Mais 1 coração.",
	"cake": "Que bolo! Vida cheia.",
	"magazine": "Treinando com a revista... chute mais forte!",
	"dog_food": "O cachorrinho adorou a ração!",
	"rifle": "Rifle novo! Soco de longe = tiro.",
}


func _on_buy(id: String) -> void:
	if GameState.buy(id):
		Sfx.play("coin", -4.0)
		_msg_label.text = BUY_MESSAGES.get(id, "Obrigado!")
		var icon: Control = _cards[id].icon
		var tw := icon.create_tween()
		tw.tween_property(icon, "scale", Vector2(1.35, 1.35), 0.1)
		tw.tween_property(icon, "scale", Vector2.ONE, 0.12)
	else:
		_msg_label.text = "Não dá pra comprar agora."
	_refresh()
	if _cards[id].btn.disabled:
		_focus_first()
