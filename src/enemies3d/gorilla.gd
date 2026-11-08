extends "res://src/enemies3d/cyclops.gd"
## Gorila: persegue o herói em bando. Muita vida e dano alto.


func _base_scale() -> float:
	return 1.1


func _make_model() -> Node3D:
	return CharacterBuilder.build_gorilla(_base_scale(), false)
