extends "res://src/enemies3d/cyclops.gd"
## Alien numa nave voadora: persegue pairando acima do chão, em bando.
## Morre com 3 golpes (fixed_hits).

var _t := 0.0


func _base_scale() -> float:
	return 1.1


func _make_model() -> Node3D:
	return CharacterBuilder.build_saucer(_base_scale())


func _ready() -> void:
	super._ready()
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	if model != null and not _dying:
		model.position.y = 0.85 + sin(_t * 3.0) * 0.13  # paira balançando
