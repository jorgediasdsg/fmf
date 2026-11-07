class_name TileBuilder
extends Object
## Monta o TileSet do jogo em código e preenche um TileMapLayer
## a partir de um mapa ASCII (1 caractere = 1 tile de 16 px):
##   '#' grama sobre terra · 'D' terra · '=' plataforma de pedra · 'X' bloco escuro

const TILE := 16
const CHAR_TO_ATLAS := {
	"#": Vector2i(0, 0),
	"D": Vector2i(1, 0),
	"=": Vector2i(2, 0),
	"X": Vector2i(3, 0),
}


static func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # camada "mundo"
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/tileset.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	for i in range(4):
		var coords := Vector2i(i, 0)
		src.create_tile(coords)
		var data := src.get_tile_data(coords, 0)
		var half := TILE / 2.0
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half),
			Vector2(half, half), Vector2(-half, half),
		]))
	return ts


static func fill(layer: TileMapLayer, ascii_map: Array) -> void:
	layer.tile_set = build_tileset()
	for y in range(ascii_map.size()):
		var row: String = ascii_map[y]
		for x in range(row.length()):
			var ch := row[x]
			if CHAR_TO_ATLAS.has(ch):
				layer.set_cell(Vector2i(x, y), 0, CHAR_TO_ATLAS[ch])


static func map_size_px(ascii_map: Array) -> Vector2:
	var w := 0
	for row in ascii_map:
		w = maxi(w, (row as String).length())
	return Vector2(w * TILE, ascii_map.size() * TILE)
