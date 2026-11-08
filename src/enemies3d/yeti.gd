extends "res://src/enemies3d/cyclops.gd"
## Yeti: persegue o herói como o ciclope, mas com bem mais vida e dano.


func _base_scale() -> float:
	return 1.15


func _make_model() -> Node3D:
	return CharacterBuilder.build_yeti(_base_scale(), false)
