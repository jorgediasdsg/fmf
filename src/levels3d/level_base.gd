class_name LevelBase
extends Node3D
## Base das fases: arena aberta estilo Brawl Stars. Vários grupos de bichos
## espalhados (eles se ajudam); ao derrotar TODOS o chefe aparece no seu ponto.
## Morte (queda ou vida zerada) → "Tente de novo!" → recarrega; vitória →
## salva o progresso e mostra o resumo.

const FALL_Y := -6.0
const HX := 55.0   # meia largura da arena (eixo X)
const HZ := 45.0   # meia profundidade (eixo Z)
const SPAWN := Vector3(0, 0.5, 38.0)
const BOSS_POINT := Vector3(0, 0.1, -34.0)
const CULL_DISTANCE := 50.0
const MOBILE_3D_SCALE := 0.75
const MOBILE_CULL_DISTANCE := 32.0
const CAMPS := [Vector2(-38, -30), Vector2(38, -30), Vector2(-40, -3), Vector2(40, -3),
	Vector2(-22, 18), Vector2(24, 19), Vector2(0, -10)]
# paredões de pedrões (x1, z1, x2, z2) com vãos largos para passar
const WALLS := [[-55, -20, -14, -20], [14, -20, 55, -20],
	[-55, 6, -26, 6], [-8, 6, 16, 6], [34, 6, 55, 6],
	[-55, 28, -30, 28], [-10, 28, 8, 28], [30, 28, 55, 28]]

@export var phase_index := 1
@export var music_name := "world1"
@export_file("*.tscn") var next_scene := ""  # vazio = volta ao título

var bush_colors: Array = []  # vazio = verdes padrão
var _enemies_left := 0
var _boss_scene: PackedScene
var _boss_spawned := false
var _coins_start := 0
var _level_start := 1
var _ended := false
var _count_label: Label
var _arrow: Polygon2D
var players: Array = []

@onready var player: CharacterBody3D = $Player
@onready var game_over: CanvasLayer = $GameOver
@onready var victory: CanvasLayer = $Victory


func _ready() -> void:
	GameState.apply_input_mode()
	GameState.current_phase = phase_index
	GameState.reset_run()
	_coins_start = GameState.coins
	_level_start = GameState.level
	player.global_position = SPAWN
	player.rig.global_position = SPAWN
	var dog := get_node_or_null("Dog") as Node3D
	if dog != null:
		dog.global_position = SPAWN + Vector3(-1.5, 0, 1)
	players = [player]
	if GameState.coop:
		var p2: CharacterBody3D = load("res://src/player3d/player.tscn").instantiate()
		p2.player_id = 2
		add_child(p2)
		p2.global_position = SPAWN + Vector3(2.0, 0, 0)
		players.append(p2)
	for pl in players:
		pl.died.connect(_on_player_died)
	game_over.action.connect(_retry)
	victory.action.connect(_finish)
	_make_objective_hud()
	_tune_for_mobile()
	_play_music()


## Celular fraco: o 3D renderiza em resolução menor (a interface continua nítida).
func _tune_for_mobile() -> void:
	if not GameState.low_end:
		return
	get_viewport().scaling_3d_scale = MOBILE_3D_SCALE
	for light in find_children("*", "DirectionalLight3D", true, false):
		(light as DirectionalLight3D).shadow_enabled = false


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


var _fps_t := 0.0


func _process(delta: float) -> void:
	if OS.is_debug_build():  # só em build de depuração: FPS no log (adb logcat)
		_fps_t += delta
		if _fps_t >= 4.0:
			_fps_t = 0.0
			var rs := RenderingServer
			print("FMF fps=%d fase=%d bichos=%d draws=%d objs=%d prims=%d" % [Engine.get_frames_per_second(),
				phase_index, _enemies_left,
				rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
				rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
				rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])


func _physics_process(_delta: float) -> void:
	if not _ended:
		for pl in players:
			if pl.global_position.y < FALL_Y:
				pl.kill()
	_update_arrow()


# ----------------------------------------------------- objetivo e chefe

func _make_objective_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	_count_label = Label.new()
	_count_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_count_label.offset_top = 6.0
	_count_label.offset_left = -120.0
	_count_label.offset_right = 120.0
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_override("font", load("res://assets/fonts/PressStart2P-Regular.ttf"))
	_count_label.add_theme_font_size_override("font_size", 8)
	_count_label.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.1))
	_count_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_count_label)
	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(0, -9), Vector2(8, 7), Vector2(0, 3), Vector2(-8, 7)])
	_arrow.color = Color(1.0, 0.92, 0.35)
	_arrow.visible = false
	layer.add_child(_arrow)


func _update_count() -> void:
	if _boss_spawned:
		_count_label.text = "Derrote o chefe!"
	else:
		_count_label.text = "Bichos restantes: %d" % _enemies_left


## Seta amarela em volta do herói apontando para o bicho (ou chefe) mais perto.
func _update_arrow() -> void:
	if _arrow == null:
		return
	var best: Node3D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var d := n.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = n
	if best == null or best_d < 15.0 or _ended:
		_arrow.visible = false
		return
	var to := best.global_position - player.global_position
	var ang := atan2(to.x, -to.z)  # câmera olha para -Z: topo da tela = -Z
	var center := get_viewport().get_visible_rect().size / 2.0 + Vector2(0, 8)
	_arrow.position = center + Vector2(sin(ang), -cos(ang)) * 70.0
	_arrow.rotation = ang
	_arrow.visible = true


func _track_enemy(e: Node) -> void:
	_enemies_left += 1
	e.defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated() -> void:
	_enemies_left -= 1
	_update_count()
	if _enemies_left <= 0 and not _boss_spawned and not _ended:
		get_tree().create_timer(1.2).timeout.connect(_spawn_boss)


func build_boss(boss_scene: PackedScene) -> void:
	_boss_scene = boss_scene
	_update_count()


func _spawn_boss() -> void:
	if _boss_spawned or _ended or _boss_scene == null:
		return
	_boss_spawned = true
	var boss := _boss_scene.instantiate()
	boss.position = BOSS_POINT
	add_child(boss)
	boss.defeated.connect(_on_victory)
	Sfx.play("boss_roar")
	_update_count()
	_count_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))


func make_shop(pos: Vector3, rot_y := 0.0) -> ShopStall:
	## Toda fase tem uma lojinha; pausar/soltar o joystick fica por conta daqui.
	var stall := ShopStall.new()
	stall.position = pos
	stall.rotation.y = rot_y
	add_child(stall)
	stall.shop.visibility_changed.connect(func():
		if stall.shop.visible:
			_release_game_actions())
	return stall


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	get_tree().paused = true
	game_over.open("Tente de novo!", "Ninguém desiste da família…", "Tentar de novo")


func _on_victory() -> void:
	if _ended:
		return
	_ended = true
	GameState.complete_phase(phase_index)
	Sfx.play("victory")
	get_tree().paused = true
	victory.open("Fase %d concluída!" % phase_index,
		"Moedas: +%d   Nível: %d" % [GameState.coins - _coins_start, GameState.level],
		"Próxima fase" if next_scene != "" else "Continuar")


func _retry() -> void:
	get_tree().paused = false
	_release_game_actions()
	GameState.reset_run()
	get_tree().reload_current_scene()


func _finish() -> void:
	get_tree().paused = false
	_release_game_actions()
	get_tree().change_scene_to_file(next_scene if next_scene != "" else "res://src/ui/title_screen.tscn")


func _release_game_actions() -> void:
	## O dedo pode estar no joystick quando a tela de morte/vitória pausa o
	## jogo; o evento de soltar se perde e a ação ficaria presa no Input.
	for action in ["move_left", "move_right", "move_up", "move_down", "punch", "kick", "run", "jump", "special"]:
		Input.action_release(action)


# ------------------------------------------------------- montagem da arena

## Chão, paredes invisíveis e árvores/palmeiras na borda.
func make_arena(ground_color: Color, edge_maker: Callable, rng: RandomNumberGenerator) -> void:
	make_ground(Vector3(HX * 2.0, 1, HZ * 2.0), ground_color, Vector3.ZERO)
	make_wall(Vector3(0, 2, -HZ - 0.5), Vector3(HX * 2.0 + 4, 5, 1))
	make_wall(Vector3(0, 2, HZ + 0.5), Vector3(HX * 2.0 + 4, 5, 1))
	make_wall(Vector3(-HX - 0.5, 2, 0), Vector3(1, 5, HZ * 2.0 + 4))
	make_wall(Vector3(HX + 0.5, 2, 0), Vector3(1, 5, HZ * 2.0 + 4))
	var x := -HX + 2.0
	while x < HX - 1.0:
		edge_maker.call(Vector3(x, 0, -HZ + rng.randf_range(0.6, 1.8)), rng)
		edge_maker.call(Vector3(x + 2.2, 0, HZ - rng.randf_range(0.6, 1.8)), rng)
		x += 4.4
	var z := -HZ + 5.0
	while z < HZ - 3.0:
		edge_maker.call(Vector3(-HX + rng.randf_range(0.6, 1.8), 0, z), rng)
		edge_maker.call(Vector3(HX - rng.randf_range(0.6, 1.8), 0, z + 2.2), rng)
		z += 4.4


## Monta o miolo da partida: paredões, pedras, moitas, lojas, grupos de bichos.
func build_arena_content(enemy_scene: PackedScene, rng: RandomNumberGenerator,
		wall_color: Color, rock_color: Color, counts: Array) -> void:
	for w in WALLS:
		make_wall_line(Vector2(w[0], w[1]), Vector2(w[2], w[3]), wall_color)
	var shops := [Vector3(-12, 0, 34), Vector3(34, 0, 1)]
	for sp in shops:
		make_shop(sp)
	var keep_out: Array = [SPAWN, BOSS_POINT] + shops
	for c in CAMPS:
		keep_out.append(Vector3(c.x, 0, c.y))
	# pedras sólidas espalhadas
	var placed := 0
	var tries := 0
	while placed < 46 and tries < 400:
		tries += 1
		var p := Vector3(rng.randf_range(-HX + 4, HX - 4), 0, rng.randf_range(-HZ + 4, HZ - 4))
		if _too_close(p, keep_out, 6.0) or _near_wall(p, 2.2):
			continue
		make_rock(p, rock_color)
		placed += 1
	# moitas: perto de cada grupo e algumas soltas
	for c in CAMPS:
		for k in range(2):
			var bp := Vector3(c.x + rng.randf_range(-9, 9), 0, c.y + rng.randf_range(-8, 8))
			if not _near_wall(bp, 2.5) and not _too_close(bp, [SPAWN, BOSS_POINT], 6.0):
				make_bush(bp)
	for k in range(8):
		var bp := Vector3(rng.randf_range(-HX + 6, HX - 6), 0, rng.randf_range(-HZ + 6, HZ - 6))
		if not _near_wall(bp, 2.5) and not _too_close(bp, [SPAWN, BOSS_POINT] + shops, 6.0):
			make_bush(bp)
	# grupos de bichos: quanto mais longe do começo, mais vida
	for i in range(CAMPS.size()):
		var c: Vector2 = CAMPS[i]
		var bonus := int(Vector2(c.x, c.y).distance_to(Vector2(SPAWN.x, SPAWN.z)) / 25.0)
		for k in range(counts[i]):
			var e := enemy_scene.instantiate()
			e.hp += bonus
			var ang := rng.randf() * TAU
			var r := rng.randf_range(1.0, 4.5)
			e.position = Vector3(c.x + cos(ang) * r, 0.1, c.y + sin(ang) * r)
			add_child(e)
			_track_enemy(e)
	_update_count()


func _too_close(p: Vector3, others: Array, dist: float) -> bool:
	for o in others:
		if Vector2(p.x, p.z).distance_to(Vector2(o.x, o.z)) < dist:
			return true
	return false


func _near_wall(p: Vector3, margin: float) -> bool:
	for w in WALLS:
		var a := Vector2(w[0], w[1])
		var b := Vector2(w[2], w[3])
		var q := Vector2(p.x, p.z)
		var t := clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		if q.distance_to(a + (b - a) * t) < margin:
			return true
	return false


## Fileira de pedrões de a até b (coordenadas X,Z), sólida.
func make_wall_line(a: Vector2, b: Vector2, color: Color) -> void:
	var length := a.distance_to(b)
	var mid := (a + b) / 2.0
	var dir := (b - a).normalized()
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, 2.0, 1.6)
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(mid.x, 1.0, mid.y)
	body.rotation.y = -atan2(dir.y, dir.x)
	add_child(body)
	var n := maxi(1, int(ceil(length / 1.7)))
	for k in range(n):
		var p := a + dir * ((k + 0.5) * length / n)
		var h := 1.7 + 0.5 * ((k + int(a.x)) % 2)
		var c := color.lightened(0.08 * ((k + int(a.y)) % 3))
		CharacterBuilder.blob(self, Vector3(2.0, h, 1.9), c, Vector3(p.x, h / 2.0 - 0.1, p.y))


## Itens de cenário longe da câmera nem são desenhados (celular/web).
func _cull_visuals(node: Node) -> void:
	var dist := MOBILE_CULL_DISTANCE if GameState.low_end else CULL_DISTANCE
	for mi in node.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).visibility_range_end = dist


func make_water(y := -0.4, color := Color(0.12, 0.5, 0.78)) -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(600, 600)
	water.mesh = plane
	water.position = Vector3(0, y, 0)
	water.material_override = ToonMaterial.flat(color, 0.15)
	add_child(water)


func make_bush(pos: Vector3) -> void:
	var bush := BushPatch.new()
	bush.position = pos
	if not bush_colors.is_empty():
		bush.greens = bush_colors
	add_child(bush)


func make_ground(size: Vector3, color: Color, pos := Vector3.ZERO, rot_y := 0.0) -> void:
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
	body.rotation.y = rot_y
	add_child(body)


func make_wall(pos: Vector3, size: Vector3, rot_y := 0.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	body.rotation.y = rot_y
	add_child(body)


func make_tree(pos: Vector3, leaf_color := Color(0.22, 0.6, 0.28), solid := false) -> void:
	## Árvore de desenho animado: tronco gordinho e copa de bolas.
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = pos
	if solid:
		(root as StaticBody3D).collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.6
		shape.height = 3.0
		col.shape = shape
		col.position.y = 1.5
		root.add_child(col)
	CharacterBuilder.cap(root, Vector3(0.55, 1.6, 0.55), Color(0.55, 0.36, 0.2), Vector3(0, 0.75, 0))
	CharacterBuilder.blob(root, Vector3(2.3, 1.9, 2.3), leaf_color, Vector3(0, 2.2, 0))
	CharacterBuilder.blob(root, Vector3(1.5, 1.3, 1.5), leaf_color.lightened(0.12), Vector3(0.3, 3.0, 0.1))
	CharacterBuilder.blob(root, Vector3(1.2, 1.1, 1.2), leaf_color.darkened(0.1), Vector3(-0.7, 2.0, 0.5))
	add_child(root)
	_cull_visuals(root)


func make_pine(pos: Vector3) -> void:
	## Pinheiro nevado, em bolas empilhadas.
	var root := Node3D.new()
	root.position = pos
	CharacterBuilder.cap(root, Vector3(0.5, 1.4, 0.5), Color(0.45, 0.3, 0.2), Vector3(0, 0.6, 0))
	var green := Color(0.15, 0.5, 0.42)
	CharacterBuilder.blob(root, Vector3(2.4, 1.3, 2.4), green, Vector3(0, 1.5, 0))
	CharacterBuilder.blob(root, Vector3(1.8, 1.2, 1.8), green.lightened(0.08), Vector3(0, 2.4, 0))
	CharacterBuilder.blob(root, Vector3(1.2, 1.1, 1.2), green.lightened(0.16), Vector3(0, 3.2, 0))
	CharacterBuilder.blob(root, Vector3(1.0, 0.45, 1.0), Color(0.96, 0.98, 1.0), Vector3(0, 3.7, 0))
	CharacterBuilder.blob(root, Vector3(1.7, 0.4, 1.7), Color(0.96, 0.98, 1.0), Vector3(0, 2.0, 0))
	add_child(root)
	_cull_visuals(root)


func make_palm(pos: Vector3, tilt := 0.0) -> void:
	## Palmeira redondinha para a ilha.
	var root := Node3D.new()
	root.position = pos
	var trunk := Node3D.new()
	trunk.rotation_degrees.z = tilt
	root.add_child(trunk)
	CharacterBuilder.cap(trunk, Vector3(0.45, 3.0, 0.45), Color(0.72, 0.5, 0.3), Vector3(0, 1.4, 0))
	var top := Node3D.new()
	top.position = Vector3(0, 3.0, 0)
	trunk.add_child(top)
	for i in range(6):
		var leaf := CharacterBuilder.blob(top, Vector3(0.45, 0.14, 1.8), Color(0.2, 0.7, 0.3),
			Vector3(0, 0.0, 0), true, "", Vector3(-25, i * 60.0, 0))
		leaf.position = Vector3(sin(deg_to_rad(i * 60.0)) * 0.8, 0.05, cos(deg_to_rad(i * 60.0)) * 0.8)
	CharacterBuilder.blob(top, Vector3(0.3, 0.3, 0.3), Color(0.45, 0.28, 0.15), Vector3(0.15, -0.2, 0.1))
	CharacterBuilder.blob(top, Vector3(0.3, 0.3, 0.3), Color(0.45, 0.28, 0.15), Vector3(-0.15, -0.2, -0.1))
	add_child(root)
	_cull_visuals(root)


func make_rock(pos: Vector3, color := Color(0.58, 0.58, 0.68)) -> void:
	## Pedrão sólido: obstáculo de verdade (o herói e os bichos contornam).
	var rock := StaticBody3D.new()
	rock.collision_layer = 1
	rock.position = pos
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = 1.4
	col.shape = shape
	col.position.y = 0.7
	rock.add_child(col)
	CharacterBuilder.blob(rock, Vector3(1.3, 1.0, 1.2), color, Vector3(0, 0.4, 0))
	CharacterBuilder.blob(rock, Vector3(0.7, 0.55, 0.6), color.lightened(0.1), Vector3(0.5, 0.15, 0.2))
	add_child(rock)
	_cull_visuals(rock)


