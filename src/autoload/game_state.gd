extends Node
## Estado global do jogo: vida, XP, nível, moedas, progresso de fases e save.
## Registrado como autoload "GameState".

signal hp_changed(hp: int, max_hp: int)
signal coins_changed(coins: int)
signal xp_changed(xp: int, to_next: int)
signal leveled_up(level: int)

const BASE_ATTACK := 3
const XP_PER_LEVEL := 20

var save_path := "user://fmf_save.json"

var max_hp := 15  # 5 corações × 3 terços
var hp := 15
var coins := 0
var xp := 0
var level := 1
var phases_done: Array = []


func attack_damage() -> int:
	return BASE_ATTACK + level


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
	var done: Variant = parsed.get("phases_done", [])
	phases_done = []
	if typeof(done) == TYPE_ARRAY:
		for p in done:
			phases_done.append(int(p))


func _apply_defaults() -> void:
	hp = max_hp
	coins = 0
	xp = 0
	level = 1
	phases_done = []
