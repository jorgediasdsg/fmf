extends "res://src/enemies3d/cyclops.gd"
## Mini alien que sai do ovo: rapidinho, dá pouco dano e morre com 2 golpes.


func _base_scale() -> float:
	return 0.6


func _make_model() -> Node3D:
	return CharacterBuilder.build_alien(_base_scale(), false)


func _ready() -> void:
	add_to_group("mini")
	super._ready()
