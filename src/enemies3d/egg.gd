extends Node3D
## Ovo do Alien Pai: voa em arco até onde o herói estava, balança e choca
## 5 mini aliens (no máximo MAX_MINIS vivos ao mesmo tempo).

const MiniScene := preload("res://src/enemies3d/alien_mini.tscn")
const FLIGHT := 0.9
const HATCH_AFTER := 1.4
const MAX_MINIS := 15

var start := Vector3.ZERO
var target := Vector3.ZERO
var _t := 0.0
var _landed := false
var _hatch := HATCH_AFTER


func _ready() -> void:
	add_to_group("egg")
	CharacterBuilder.build_egg(self)
	position = start


func _physics_process(delta: float) -> void:
	if not _landed:
		_t += delta
		var k := clampf(_t / FLIGHT, 0.0, 1.0)
		position = start.lerp(target, k) + Vector3(0, sin(k * PI) * 3.2, 0)
		rotation.x += 6.0 * delta
		if k >= 1.0:
			_landed = true
			rotation = Vector3.ZERO
			position = target
		return
	_hatch -= delta
	rotation.z = sin(_hatch * 22.0) * 0.3 * (1.0 - _hatch / HATCH_AFTER + 0.2)
	if _hatch <= 0.0:
		_hatch_minis()


func _hatch_minis() -> void:
	var parent := get_parent()
	var room := MAX_MINIS - get_tree().get_nodes_in_group("mini").size()
	for i in range(mini(5, maxi(room, 0))):
		var m := MiniScene.instantiate()
		var a := i * TAU / 5.0
		m.position = position + Vector3(cos(a), 0.1, sin(a)) * 1.1
		parent.call_deferred("add_child", m)
	Sfx.play("coin", -8.0)
	queue_free()
