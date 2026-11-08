extends RefCounted
## Testes do autoload GameState (lógica pura: vida, XP, moedas, save).

const SAVE_PATH := "user://test_fmf_save.json"


func _new_gs() -> Node:
	var script: Script = load("res://src/autoload/game_state.gd")
	if script == null:
		return null
	var gs: Node = script.new()
	gs.save_path = SAVE_PATH
	return gs


func _cleanup(gs: Node) -> void:
	if gs != null:
		gs.free()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func test_dano_acumulado_mata_exatamente_em_15() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	if gs.take_damage(5):
		r = "morreu com 5 de dano"
	elif gs.take_damage(9):
		r = "morreu com 14 de dano"
	elif not gs.take_damage(1):
		r = "não morreu com 15 de dano"
	elif gs.hp != 0:
		r = "hp devia ser 0, é %d" % gs.hp
	_cleanup(gs)
	return r


func test_dano_nunca_deixa_hp_negativo() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.take_damage(100)
	if gs.hp != 0:
		r = "hp devia clampar em 0, é %d" % gs.hp
	_cleanup(gs)
	return r


func test_xp_sobe_nivel_e_carrega_excedente() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.add_xp(25)  # nível 1 precisa de 20
	if gs.level != 2:
		r = "nível devia ser 2, é %d" % gs.level
	elif gs.xp != 5:
		r = "xp devia carregar 5, é %d" % gs.xp
	_cleanup(gs)
	return r


func test_xp_em_cascata_sobe_varios_niveis() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.add_xp(65)  # 20 (nv1→2) + 40 (nv2→3) + 5 sobrando
	if gs.level != 3:
		r = "nível devia ser 3, é %d" % gs.level
	elif gs.xp != 5:
		r = "xp devia sobrar 5, é %d" % gs.xp
	_cleanup(gs)
	return r


func test_dano_de_ataque_cresce_com_nivel() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	if gs.attack_damage() != 4:
		r = "nível 1 devia bater 4, bate %d" % gs.attack_damage()
	else:
		gs.add_xp(20)
		if gs.attack_damage() != 5:
			r = "nível 2 devia bater 5, bate %d" % gs.attack_damage()
	_cleanup(gs)
	return r


func test_save_e_load_preservam_estado() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	gs.add_coins(42)
	gs.add_xp(25)  # nível 2, xp 5
	gs.complete_phase(1)
	gs.save()
	gs.free()

	var gs2 := _new_gs()
	var r := ""
	gs2.load_save()
	if gs2.coins != 42:
		r = "coins devia ser 42, é %d" % gs2.coins
	elif gs2.level != 2:
		r = "level devia ser 2, é %d" % gs2.level
	elif gs2.xp != 5:
		r = "xp devia ser 5, é %d" % gs2.xp
	elif not gs2.phases_done.has(1):
		r = "fase 1 devia estar concluída"
	_cleanup(gs2)
	return r


func test_load_sem_arquivo_vira_jogo_novo() -> String:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.load_save()
	if gs.coins != 0 or gs.level != 1 or gs.xp != 0 or not gs.phases_done.is_empty():
		r = "estado devia ser de jogo novo"
	_cleanup(gs)
	return r


func test_load_com_json_invalido_vira_jogo_novo() -> String:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string("{isso não é json válido%%%")
	f.close()
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.load_save()
	if gs.coins != 0 or gs.level != 1 or not gs.phases_done.is_empty():
		r = "save corrompido devia virar jogo novo"
	_cleanup(gs)
	return r


func test_reset_run_enche_vida() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.take_damage(7)
	gs.reset_run()
	if gs.hp != gs.max_hp:
		r = "reset_run devia encher a vida"
	_cleanup(gs)
	return r


func test_heal_nao_passa_do_maximo() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.take_damage(2)
	gs.heal(3)
	if gs.hp != gs.max_hp:
		r = "heal devia limitar no máximo (hp=%d)" % gs.hp
	gs.take_damage(9)
	gs.heal(3)
	if r == "" and gs.hp != gs.max_hp - 9 + 3:
		r = "heal(3) devia curar 3 (hp=%d)" % gs.hp
	_cleanup(gs)
	return r


func test_loja_compras() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.coins = 100
	if gs.buy("apple"):
		r = "maçã com vida cheia não devia gastar moeda"
	gs.take_damage(9)
	if r == "" and (not gs.buy("apple") or gs.coins != 94 or gs.hp != gs.max_hp - 6):
		r = "maçã devia custar 6 e curar 3 (coins=%d hp=%d)" % [gs.coins, gs.hp]
	if r == "" and (not gs.buy("cake") or gs.hp != gs.max_hp or gs.coins != 74):
		r = "bolo devia custar 20 e curar tudo (coins=%d hp=%d)" % [gs.coins, gs.hp]
	gs.coins = 200
	var dmg: int = gs.attack_damage()
	if r == "" and (not gs.buy("magazine") or gs.attack_damage() != dmg + 1):
		r = "revista devia dar +1 de dano"
	if r == "" and gs.price_of("magazine") != 50:
		r = "segunda revista devia custar 50, custa %d" % gs.price_of("magazine")
	gs.coins = 0
	if r == "" and gs.buy("magazine"):
		r = "sem moedas não devia comprar"
	_cleanup(gs)
	return r


func test_rifle_so_nas_fases_avancadas() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.coins = 500
	gs.current_phase = 2
	if gs.buy("rifle"):
		r = "rifle não devia estar à venda na fase 2"
	gs.current_phase = 3
	if r == "" and (not gs.buy("rifle") or not gs.has_rifle or gs.coins != 340):
		r = "rifle devia custar 160 na fase 3 (coins=%d)" % gs.coins
	if r == "" and gs.buy("rifle"):
		r = "rifle só pode ser comprado uma vez"
	gs.save()
	gs.has_rifle = false
	gs.load_save()
	if r == "" and not gs.has_rifle:
		r = "has_rifle devia voltar do save"
	_cleanup(gs)
	return r


func test_bonus_de_ataque_persiste_no_save() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.attack_bonus = 2
	gs.save()
	gs.attack_bonus = 0
	gs.load_save()
	if gs.attack_bonus != 2:
		r = "attack_bonus devia voltar do save (=%d)" % gs.attack_bonus
	_cleanup(gs)
	return r


func test_personagem_escolhido_persiste() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.set_character("menina")
	gs.save()
	gs.set_character("zack")
	gs.load_save()
	if gs.character != "menina":
		r = "personagem devia voltar do save (=%s)" % gs.character
	gs.set_character("invalido")
	if r == "" and gs.character != "zack":
		r = "personagem inválido devia virar zack"
	_cleanup(gs)
	return r


func test_racao_super_premio_sobe_dano_do_cao() -> String:
	var gs := _new_gs()
	if gs == null:
		return "game_state.gd não existe"
	var r := ""
	gs.coins = 100
	if gs.dog_bite_bonus() != 0:
		r = "sem ração o bônus do cão devia ser 0"
	if r == "" and (not gs.buy("dog_food") or gs.dog_bite_bonus() != 2 or gs.coins != 55):
		r = "ração devia custar 45 e dar +2 (coins=%d bônus=%d)" % [gs.coins, gs.dog_bite_bonus()]
	if r == "" and gs.price_of("dog_food") != 70:
		r = "segunda ração devia custar 70, custa %d" % gs.price_of("dog_food")
	gs.save()
	gs.dog_bonus = 0
	gs.load_save()
	if r == "" and gs.dog_bonus != 1:
		r = "dog_bonus devia voltar do save (=%d)" % gs.dog_bonus
	_cleanup(gs)
	return r
