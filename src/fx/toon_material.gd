class_name ToonMaterial
extends Object
## Fábrica do estilo visual: material flat toon+rim e contorno por casco invertido.

const TOON_SHADER := preload("res://src/fx/toon.gdshader")
const OUTLINE_SHADER := preload("res://src/fx/outline.gdshader")


static func flat(color: Color, rim_strength := 0.55) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON_SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("rim_strength", rim_strength)
	return m


static func add_outline(mi: MeshInstance3D, thickness := 0.03) -> void:
	var dup := MeshInstance3D.new()
	dup.mesh = mi.mesh
	var m := ShaderMaterial.new()
	m.shader = OUTLINE_SHADER
	m.set_shader_parameter("thickness", thickness)
	dup.material_override = m
	mi.add_child(dup)
