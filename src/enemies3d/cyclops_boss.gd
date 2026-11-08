extends "res://src/enemies3d/cyclops.gd"
## Ciclope Grande: a cada intervalo, telegrafou por 1 s (pisca e cresce)
## e investe em linha reta contra a posição do Zack. Ignora o cachorro.

const CHARGE_INTERVAL := 4.0
const TELEGRAPH_TIME := 1.0
const CHARGE_TIME := 0.8
const CHARGE_SPEED := 10.0

enum BossState { NORMAL, TELEGRAPH, CHARGE }

var _bstate := BossState.NORMAL
var _timer := CHARGE_INTERVAL
var _charge_dir := Vector3.ZERO


func _physics_process(delta: float) -> void:
	if _dying:
		return
	var player := _target()
	match _bstate:
		BossState.NORMAL:
			super._physics_process(delta)
			if _can_see(player) and global_position.distance_to(player.global_position) < chase_range:
				_timer -= delta
				if _timer <= 0.0:
					_bstate = BossState.TELEGRAPH
					_timer = TELEGRAPH_TIME
					Sfx.play("boss_roar", -3.0)
		BossState.TELEGRAPH:
			velocity.x = 0.0
			velocity.z = 0.0
			if not _can_see(player):  # sumiu no mato: desiste da investida
				model.scale = Vector3.ONE * _base_scale()
				_bstate = BossState.NORMAL
				_timer = CHARGE_INTERVAL
				return
			var pulse := 1.0 + 0.12 * sin(_timer * 25.0)
			model.scale = Vector3.ONE * _base_scale() * pulse
			if player != null:
				var dir := player.global_position - global_position
				dir.y = 0.0
				model.rotation.y = atan2(dir.x, dir.z)
				_charge_dir = dir.normalized()
			_timer -= delta
			if _timer <= 0.0:
				model.scale = Vector3.ONE * _base_scale()
				_bstate = BossState.CHARGE
				_timer = CHARGE_TIME
			move_and_slide()
		BossState.CHARGE:
			if not is_on_floor():
				velocity.y -= 19.6 * delta
			velocity.x = _charge_dir.x * CHARGE_SPEED
			velocity.z = _charge_dir.z * CHARGE_SPEED
			if player != null:
				var to_player := player.global_position - global_position
				to_player.y = 0.0
				if to_player.length() < contact_range * 1.4 and player.has_method("hurt"):
					player.hurt(contact_damage, global_position)
			_timer -= delta
			if _timer <= 0.0 or is_on_wall():
				_bstate = BossState.NORMAL
				_timer = CHARGE_INTERVAL
			move_and_slide()
