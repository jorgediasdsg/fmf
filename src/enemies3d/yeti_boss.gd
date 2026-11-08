extends "res://src/enemies3d/cyclops_boss.gd"
## Yeti Gigante: investida telegrafada (herdada do chefe ciclope), bem maior.


func _base_scale() -> float:
	return 2.0


func _make_model() -> Node3D:
	return CharacterBuilder.build_yeti(_base_scale(), true)
