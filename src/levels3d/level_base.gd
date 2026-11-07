class_name LevelBase
extends Node3D
## Base das fases: música em loop, morte (queda ou vida zerada) → "Tente de
## novo!" → recarrega a fase; vitória → salva progresso e mostra o resumo.
## A fase concreta constrói o terreno e chama _register_zone/_register_boss.

const FALL_Y := -6.0

@export var phase_index := 1
@export var music_name := "world1"

var _zones: Array = []  # [{enemies: int, gate: Node3D}]
var _coins_start := 0
var _level_start := 1
var _ended := false

@onready var player: CharacterBody3D = $Player
@onready var game_over: CanvasLayer = $GameOver
@onready var victory: CanvasLayer = $Victory


func _ready() -> void:
	GameState.reset_run()
	_coins_start = GameState.coins
	_level_start = GameState.level
	player.died.connect(_on_player_died)
	game_over.action.connect(_retry)
	victory.action.connect(_finish)
	_play_music()


func _play_music() -> void:
	var stream := load("res://assets/audio/%s.wav" % music_name) as AudioStreamWAV
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	var music := AudioStreamPlayer.new()
	music.name = "Music"
	music.stream = stream
	music.volume_db = -10.0
	add_child(music)
	music.play()


func _physics_process(_delta: float) -> void:
	if not _ended and player.global_position.y < FALL_Y:
		player.kill()


func _register_zone(enemies: Array, gate: Node3D) -> void:
	var zone := {"left": enemies.size(), "gate": gate}
	_zones.append(zone)
	for e in enemies:
		e.defeated.connect(func():
			zone.left -= 1
			if zone.left <= 0 and zone.gate != null:
				_open_gate(zone.gate)
		)


func _register_boss(boss: Node) -> void:
	boss.defeated.connect(_on_victory)


func _open_gate(gate: Node3D) -> void:
	Sfx.play("levelup", -6.0)
	var tw := create_tween()
	tw.tween_property(gate, "position:y", gate.position.y - 3.5, 0.7)
	tw.tween_callback(gate.queue_free)


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	get_tree().paused = true
	game_over.open("Tente de novo!", "O Zack não desistiu da família…", "Tentar de novo")


func _on_victory() -> void:
	if _ended:
		return
	_ended = true
	GameState.complete_phase(phase_index)
	Sfx.play("victory")
	get_tree().paused = true
	victory.open("Fase %d concluída!" % phase_index,
		"Moedas: +%d   Nível: %d" % [GameState.coins - _coins_start, GameState.level],
		"Continuar")


func _retry() -> void:
	get_tree().paused = false
	_release_game_actions()
	GameState.reset_run()
	get_tree().reload_current_scene()


func _finish() -> void:
	get_tree().paused = false
	_release_game_actions()
	get_tree().change_scene_to_file("res://src/ui/title_screen.tscn")


func _release_game_actions() -> void:
	## O dedo pode estar no joystick quando a tela de morte/vitória pausa o
	## jogo; o evento de soltar se perde e a ação ficaria presa no Input.
	for action in ["move_left", "move_right", "move_up", "move_down", "attack"]:
		Input.action_release(action)


# ---------------------------------------------------- construção de cenário

func make_ground(size: Vector3, color: Color, pos := Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = ToonMaterial.flat(color, 0.15)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(mesh)
	body.add_child(col)
	body.position = pos + Vector3(0, -size.y / 2.0, 0)
	add_child(body)


func make_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)


func make_tree(pos: Vector3, leaf_color := Color(0.16, 0.38, 0.22)) -> void:
	var root := Node3D.new()
	root.position = pos
	var trunk := MeshInstance3D.new()
	var tmesh := CylinderMesh.new()
	tmesh.top_radius = 0.22
	tmesh.bottom_radius = 0.3
	tmesh.height = 1.4
	trunk.mesh = tmesh
	trunk.position.y = 0.7
	trunk.material_override = ToonMaterial.flat(Color(0.42, 0.29, 0.19), 0.2)
	ToonMaterial.add_outline(trunk, 0.04)
	root.add_child(trunk)
	var leaves := MeshInstance3D.new()
	var lmesh := CylinderMesh.new()
	lmesh.top_radius = 0.0
	lmesh.bottom_radius = 1.3
	lmesh.height = 2.8
	leaves.mesh = lmesh
	leaves.position.y = 2.6
	leaves.material_override = ToonMaterial.flat(leaf_color, 0.3)
	ToonMaterial.add_outline(leaves, 0.05)
	root.add_child(leaves)
	add_child(root)


func make_rock(pos: Vector3) -> void:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 0.7
	rock.mesh = mesh
	rock.position = pos
	rock.material_override = ToonMaterial.flat(Color(0.45, 0.44, 0.5), 0.2)
	ToonMaterial.add_outline(rock, 0.04)
	add_child(rock)


func make_gate(pos: Vector3, width: float) -> Node3D:
	var gate := StaticBody3D.new()
	gate.add_to_group("gate")
	gate.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 3.0, width)
	col.shape = shape
	col.position.y = 1.5
	gate.add_child(col)
	var n := int(width / 1.1)
	for i in range(n):
		var thorn := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.8, 1.6 + 0.6 * (i % 2), 0.9)
		thorn.mesh = mesh
		thorn.position = Vector3(0, mesh.size.y / 2.0, -width / 2.0 + (i + 0.5) * width / n)
		thorn.material_override = ToonMaterial.flat(Color(0.2, 0.3, 0.16), 0.2)
		ToonMaterial.add_outline(thorn, 0.04)
		gate.add_child(thorn)
	gate.position = pos
	add_child(gate)
	return gate
