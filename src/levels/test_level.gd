extends Node2D
## Nível de teste do player (removido na Task 6).

const MAP := [
	"................................",
	"................................",
	"................................",
	"................................",
	"..........===..................",
	"................................",
	"......===.......===.............",
	"................................",
	"##########....##################",
	"DDDDDDDDDD....DDDDDDDDDDDDDDDDDD",
	"DDDDDDDDDD....DDDDDDDDDDDDDDDDDD",
]

@onready var tiles: TileMapLayer = $Tiles


func _ready() -> void:
	TileBuilder.fill(tiles, MAP)
	var size := TileBuilder.map_size_px(MAP)
	var cam: Camera2D = $Player/Camera
	cam.limit_left = 0
	cam.limit_right = int(size.x)
	cam.limit_bottom = int(size.y)
	cam.limit_top = -int(size.y)
