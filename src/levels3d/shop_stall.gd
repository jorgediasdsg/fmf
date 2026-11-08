class_name ShopStall
extends Node3D
## Barraca de feira com um gato vendedor. Ao chegar perto, abre o menu da
## lojinha; só reabre depois que o jogador se afastar (evita loop ao sair).

const TRIGGER_RADIUS := 2.6

var shop: ShopMenu
var _armed := true
var _area: Area3D


func _ready() -> void:
	_build_visual()
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = TRIGGER_RADIUS
	sh.height = 3.0
	cs.shape = sh
	cs.position.y = 1.0
	_area.add_child(cs)
	add_child(_area)
	_area.body_entered.connect(_on_enter)
	_area.body_exited.connect(func(b): if b.is_in_group("player"): _armed = true)
	shop = ShopMenu.new()
	add_child(shop)


func _on_enter(body: Node) -> void:
	if _armed and body.is_in_group("player"):
		_armed = false
		shop.open()


func _build_visual() -> void:
	var cat := Color(0.98, 0.62, 0.22)
	var wood := Color(0.62, 0.38, 0.22)
	var B := CharacterBuilder
	# balcão arredondado (cápsula deitada)
	B.cap(self, Vector3(0.95, 2.5, 0.95), wood, Vector3(0, 0.5, 0.5), true, "Counter", Vector3(0, 0, 90))
	for x in [-1.1, 1.1]:
		B.cap(self, Vector3(0.16, 2.2, 0.16), wood, Vector3(x, 1.1, -0.35))
	# toldo listrado vermelho/branco, bem redondo
	for i in range(6):
		var c := Color(0.95, 0.2, 0.22) if i % 2 == 0 else Color(1.0, 0.97, 0.9)
		B.cap(self, Vector3(0.42, 1.7, 0.3), c, Vector3(-1.0 + i * 0.4, 2.25 - 0.1 * absf(i - 2.5) * 0.4, 0.2), true, "", Vector3(90, 0, 0))
	# gato vendedor atrás do balcão (olha para +Z)
	var cat_root := Node3D.new()
	cat_root.position = Vector3(0, 0, -0.1)
	add_child(cat_root)
	B.cap(cat_root, Vector3(0.6, 0.8, 0.5), cat, Vector3(0, 0.55, 0))
	B.blob(cat_root, Vector3(0.78, 0.66, 0.66), cat, Vector3(0, 1.22, 0))
	for x in [-0.24, 0.24]:
		B.cap(cat_root, Vector3(0.18, 0.3, 0.12), cat, Vector3(x, 1.62, 0), true, "", Vector3(0, 0, -x * 80))
		B.blob(cat_root, Vector3(0.12, 0.16, 0.05), B.COL.pupil, Vector3(x * 0.7, 1.26, 0.32), false)
	B.blob(cat_root, Vector3(0.1, 0.07, 0.05), B.COL.cheek, Vector3(0, 1.14, 0.33), false)
	# maçãs no balcão
	for x in [-0.7, -0.4, 0.7]:
		var a := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		a.mesh = sm
		a.position = Vector3(x, 1.02, 0.5)
		a.material_override = ToonMaterial.flat(Color(0.88, 0.14, 0.16), 0.9)
		add_child(a)
	# bloqueia a barraca (o player não atravessa)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var bc := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.4, 2.0, 1.6)
	bc.shape = bs
	bc.position = Vector3(0, 1.0, 0.2)
	body.add_child(bc)
	add_child(body)
