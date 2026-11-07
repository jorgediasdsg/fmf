extends RefCounted
## O estilo visual usa poucos materiais: a fábrica deve cachear por cor+rim
## (um ShaderMaterial por combinação, não um por mesh).


func test_materiais_iguais_sao_a_mesma_instancia() -> String:
	var tm: Script = load("res://src/fx/toon_material.gd")
	var a: ShaderMaterial = tm.flat(Color(0.3, 0.5, 0.2), 0.4)
	var b: ShaderMaterial = tm.flat(Color(0.3, 0.5, 0.2), 0.4)
	if a != b:
		return "mesma cor+rim devia reutilizar o mesmo material"
	var c: ShaderMaterial = tm.flat(Color(0.9, 0.1, 0.1), 0.4)
	if a == c:
		return "cores diferentes deviam gerar materiais diferentes"
	return ""
