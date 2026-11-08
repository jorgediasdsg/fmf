extends Node
## Estado global do jogo: vida, XP, nível, moedas, progresso de fases e save.
## Registrado como autoload "GameState".

signal hp_changed(hp: int, max_hp: int)
signal coins_changed(coins: int)
signal xp_changed(xp: int, to_next: int)
signal leveled_up(level: int)

const BASE_ATTACK := 3
const XP_PER_LEVEL := 20
const FOOD_HEAL := 3  # um coração inteiro

## Itens do bazar. price = preço base; cada compra repetida encarece (price_of).
const SHOP_ITEMS := {
	"apple": {"name": "Maçã", "desc": "Cura 1 coração", "price": 6, "min_phase": 1},
	"cake": {"name": "Bolo gigante", "desc": "Cura tudo", "price": 20, "min_phase": 1},
	"magazine": {"name": "Revista de Treinamento", "desc": "Chute +1", "price": 30, "min_phase": 1},
	"dog_food": {"name": "Ração Super Prêmio", "desc": "Cão +2 dano", "price": 45, "min_phase": 1},
	"rifle": {"name": "Rifle", "desc": "Atira de longe", "price": 160, "min_phase": 3},
}
const SHOP_ORDER := ["apple", "cake", "magazine", "dog_food", "rifle"]
const DOG_FOOD_BONUS := 2

var save_path := "user://fmf_save.json"

var max_hp := 15  # 5 corações × 3 terços
var hp := 15
var coins := 0
var xp := 0
var level := 1
var phases_done: Array = []
var low_end := false         # celular/tela de toque: gráficos mais leves
var coop := false           # 2 jogadores: P1 teclado, P2 controle
var character2 := "loiro"   # herói do jogador 2
var character := "zack"  # herói escolhido: loiro / zack / menina
var dog_bonus := 0  # Ração Super Prêmio: cada uma dá +2 de dano ao cão
var has_rifle := false      # comprado no bazar (fase 3+): atira de longe
var current_phase := 1      # fase em andamento (libera itens do bazar)
var attack_bonus := 0  # comprado na lojinha, vale para sempre


func set_character(id: String) -> void:
	character = id if CharacterBuilder.LOOKS.has(id) else "zack"


func set_character2(id: String) -> void:
	character2 = id if CharacterBuilder.LOOKS.has(id) else "loiro"


## Jogador vivo mais perto de pos (com visible_only, ignora quem está escondido).
func nearest_player(from: Vector3, visible_only := false) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for p in get_tree().get_nodes_in_group("player"):
		var n := p as Node3D
		if n == null or not is_instance_valid(n):
			continue
		if n.get("_dead") == true:
			continue
		if visible_only and n.has_method("is_hidden") and n.is_hidden():
			continue
		var d := n.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = n
	return best


## Primeiro controle conectado (jogador 2) ou -1.
func joy_device() -> int:
	var pads := Input.get_connected_joypads()
	return pads[0] if not pads.is_empty() else -1


## Soco/chute/correr (além de mover/pular do projeto). Teclado: J soco, K chute,
## Shift corre, Espaço pula. Controle: X soco, Y chute, B/RB corre, A pula.
func _register_actions() -> void:
	# Menus 100% no controle: A (ou Start) confirma, B volta. (O padrão do Godot
	# não liga o A a "confirmar" nem o B a "voltar".)
	InputMap.action_add_event("ui_accept", _btn(JOY_BUTTON_A))
	InputMap.action_add_event("ui_accept", _btn(JOY_BUTTON_START))
	InputMap.action_add_event("ui_cancel", _btn(JOY_BUTTON_B))
	if InputMap.has_action("interact"):
		InputMap.erase_action("interact")  # liberava o Y do controle, agora é chute
	_add_action("punch", [_key(KEY_J), _key(KEY_Z), _btn(JOY_BUTTON_X)])
	_add_action("kick", [_key(KEY_K), _key(KEY_X), _btn(JOY_BUTTON_Y)])
	var rt := InputEventJoypadMotion.new()
	rt.axis = JOY_AXIS_TRIGGER_RIGHT
	rt.axis_value = 1.0
	var lt := InputEventJoypadMotion.new()
	lt.axis = JOY_AXIS_TRIGGER_LEFT
	lt.axis_value = 1.0
	_add_action("special", [_key(KEY_Q), _btn(JOY_BUTTON_LEFT_SHOULDER), lt])
	_add_action("run", [_key(KEY_SHIFT), _btn(JOY_BUTTON_B), _btn(JOY_BUTTON_RIGHT_SHOULDER), rt])


func _add_action(name: String, events: Array) -> void:
	if InputMap.has_action(name):
		InputMap.erase_action(name)
	InputMap.add_action(name, 0.2)
	for ev in events:
		InputMap.action_add_event(name, ev)


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	return ev


func _btn(index: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = index
	return ev


## No co-op o controle é só do jogador 2: tira os eventos de controle das
## ações do jogador 1 (teclado/toque). Sem co-op, restaura tudo.
func apply_input_mode() -> void:
	InputMap.load_from_project_settings()
	_register_actions()
	if not coop:
		return
	for action in ["move_left", "move_right", "move_up", "move_down", "punch", "kick", "run", "jump", "special"]:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion or ev is InputEventJoypadButton:
				InputMap.action_erase_event(action, ev)


## Primeira fase ainda não vencida, na ordem; tudo vencido recomeça na 1.
func next_phase_path() -> String:
	if not phases_done.has(1):
		return "res://src/levels3d/phase_1.tscn"
	if not phases_done.has(2):
		return "res://src/levels3d/phase_2.tscn"
	if not phases_done.has(3):
		return "res://src/levels3d/phase_3.tscn"
	if not phases_done.has(4):
		return "res://src/levels3d/phase_4.tscn"
	if not phases_done.has(5):
		return "res://src/levels3d/phase_5.tscn"
	return "res://src/levels3d/phase_1.tscn"


func attack_damage() -> int:
	return BASE_ATTACK + level + attack_bonus


func xp_to_next() -> int:
	return XP_PER_LEVEL * level


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next())


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func take_damage(amount: int) -> bool:
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	return hp == 0


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + maxi(0, amount))
	hp_changed.emit(hp, max_hp)


func price_of(item: String) -> int:
	var base: int = SHOP_ITEMS[item].price
	if item == "magazine":
		return base + 20 * attack_bonus
	if item == "dog_food":
		return base + 25 * dog_bonus
	return base


func dog_bite_bonus() -> int:
	return DOG_FOOD_BONUS * dog_bonus


func is_unlocked(item: String) -> bool:
	return SHOP_ITEMS.has(item) and current_phase >= int(SHOP_ITEMS[item].min_phase)


func can_buy(item: String) -> bool:
	if not is_unlocked(item) or coins < price_of(item):
		return false
	if item == "rifle" and has_rifle:
		return false
	return not (item in ["apple", "cake"] and hp >= max_hp)


## Compra e aplica o item. Devolve false se faltou moeda ou não faz sentido
## (comida com a vida cheia não gasta moeda).
func buy(item: String) -> bool:
	if not can_buy(item):
		return false
	coins -= price_of(item)
	coins_changed.emit(coins)
	match item:
		"apple":
			heal(FOOD_HEAL)
		"cake":
			heal_full()
		"magazine":
			attack_bonus += 1
		"rifle":
			has_rifle = true
		"dog_food":
			dog_bonus += 1
	save()
	return true


func heal_full() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)


func reset_run() -> void:
	heal_full()


func complete_phase(index: int) -> void:
	if not phases_done.has(index):
		phases_done.append(index)
	save()


func save() -> void:
	var data := {
		"coins": coins,
		"xp": xp,
		"level": level,
		"phases_done": phases_done,
		"attack_bonus": attack_bonus,
		"dog_bonus": dog_bonus,
		"has_rifle": has_rifle,
		"character": character,
		"character2": character2,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()


func load_save() -> void:
	_apply_defaults()
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", 0))
	xp = int(parsed.get("xp", 0))
	level = maxi(1, int(parsed.get("level", 1)))
	attack_bonus = maxi(0, int(parsed.get("attack_bonus", 0)))
	dog_bonus = maxi(0, int(parsed.get("dog_bonus", 0)))
	has_rifle = bool(parsed.get("has_rifle", false))
	set_character(str(parsed.get("character", "zack")))
	set_character2(str(parsed.get("character2", "loiro")))
	var done: Variant = parsed.get("phases_done", [])
	phases_done = []
	if typeof(done) == TYPE_ARRAY:
		for p in done:
			phases_done.append(int(p))


func _ready() -> void:
	low_end = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	CharacterBuilder.low_detail = low_end
	apply_input_mode()


func _apply_defaults() -> void:
	hp = max_hp
	coins = 0
	xp = 0
	level = 1
	phases_done = []
	attack_bonus = 0
	dog_bonus = 0
	has_rifle = false
	character = "zack"
