extends Node
## Tocador global de efeitos sonoros (autoload "Sfx").

func _ready() -> void:
	# os jingles de vitória/derrota tocam com a árvore pausada
	process_mode = Node.PROCESS_MODE_ALWAYS


var _streams := {
	"hit": preload("res://assets/audio/hit.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"jump": preload("res://assets/audio/jump.wav"),
	"levelup": preload("res://assets/audio/levelup.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
	"boss_roar": preload("res://assets/audio/boss_roar.wav"),
}


func play(name: String, volume_db: float = 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _streams[name]
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
