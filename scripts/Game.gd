extends Control

@onready var gs: GameState = GameState.new()
@onready var ai: AISimple = AISimple.new()

var player_count := 2
var EIGHTS_DISTRIBUTE_BY_DEFAULT := false # для >2 гравців і множинної 8ки

func _ready():
	add_child(gs)
	add_child(ai)
	gs.start_match(player_count, [false, true, true, true]) # 0-й — людина
	gs.start_round()
	_connect_ui()
	_turn_banner()

func _connect_ui():
	if has_node("DrawBtn"):
		$DrawBtn.pressed.connect(on_draw_pressed)
	if has_node("PassBtn"):
		$PassBtn.pressed.connect(on_pass_pressed)
	if has_node("AutoBtn"):
		$AutoBtn.pressed.connect(on_auto_pressed)

func _turn_banner():
	if has_node("Status"):
		$Status.text = "Хід гравця %d" % gs.current_idx

func on_draw_pressed():
	# Якщо активний режим "накрий сам" після 6 — тягнемо, доки не зможемо покрити, і одразу граємо
	if gs.rules.must_cover_self:
		var tried := 0
		while gs.rules.must_cover_self and tried < 60:
			gs.draw_cards(gs.current_idx, 1)
			tried += 1
			var legal = gs.legal_groups_for_hand(gs.players[gs.current_idx].hand)
			if not legal.is_empty():
				_play_group(legal[0], -1, {})
		return
	# Загальний випадок: взяти 1 і пас
	gs.draw_cards(gs.current_idx, 1)
	_end_turn()

func on_pass_pressed():
	if gs.rules.must_cover_self:
		if has_node("Status"):
			$Status.text = "Ти поклав 6 — мусиш накрити. Добирай до можливості."
		return
	_end_turn()

# Для швидкої гри на телефоні: кнопка "Auto" робить хід за людину AI-логікою
func on_auto_pressed():
	if gs.players[gs.current_idx]["is_bot"]:
		return
	var mv = ai.choose_move(gs, gs.current_idx)
	if mv["type"] == "play":
		var o := {}
		var group := mv["group"]
		if group.size() > 0 and group[0].rank == Card.Rank.R8 and player_count > 2 and group.size() > 1:
			o["distribute_eights"] = EIGHTS_DISTRIBUTE_BY_DEFAULT
		_play_group(group, mv.get("declare", -1), o)
	else:
		on_draw_pressed()

func on_play_pressed(selected_cards: Array[Card], declared_suit: int = -1):
	var groups = _group_by_rank(selected_cards)
	if groups.size() != 1:
		if has_node("Status"): $Status.text = "Обери 1–4 карти одного рангу"
		return
	var group = groups[0]
	if not gs.rules.can_play_group(group, gs.top_card()):
		if has_node("Status"): $Status.text = "Хід нелегальний"
		return
	var opts := {}
	if group[0].rank == Card.Rank.R8 and group.size() > 1 and player_count > 2:
		opts["distribute_eights"] = EIGHTS_DISTRIBUTE_BY_DEFAULT
	_play_group(group, declared_suit, opts)

func _play_group(group: Array[Card], declared_suit: int, opts: Dictionary):
	gs.play_group(gs.current_idx, group, declared_suit, opts)

	if gs.is_round_over():
		gs.settle_round_scores()
		var loser = gs.has_match_loser()
		if loser != -1:
			if has_node("Status"): $Status.text = "Гравець %d програв матч (>125)" % loser
			return
		gs.start_round()
		_turn_banner()
		return

	# Якщо треба накривати 6 — не завершуємо хід
	if gs.rules.must_cover_self:
		_turn_banner()
		if has_node("Status"):
			$Status.text = "Гравець %d поклав 6 — мусить накрити у цей же хід" % gs.current_idx
		# Якщо бот — продовжує сам
		if gs.players[gs.current_idx]["is_bot"]:
			await get_tree().create_timer(0.6).timeout
			var safety := 0
			while gs.rules.must_cover_self and safety < 40:
				var mv = ai.choose_move(gs, gs.current_idx)
				if mv["type"] == "play":
					var o := {}
					if mv.has("group") and mv["group"][0].rank == Card.Rank.R8 and player_count > 2 and mv["group"].size() > 1:
						o["distribute_eights"] = False
					gs.play_group(gs.current_idx, mv["group"], mv.get("declare", -1), o)
				else:
					gs.draw_cards(gs.current_idx, 1)
				safety += 1
			if gs.is_round_over():
				gs.settle_round_scores()
				var l2 = gs.has_match_loser()
				if l2 != -1:
					if has_node("Status"): $Status.text = "Гравець %d програв матч (>125)" % l2
					return
			_end_turn()
			return

	_end_turn()

func _end_turn():
	gs.end_of_turn_advance()
	gs.process_start_of_turn()
	_turn_banner()
	if gs.players[gs.current_idx]["is_bot"] and not gs.rules.must_cover_self:
		await get_tree().create_timer(0.6).timeout
		var mv = ai.choose_move(gs, gs.current_idx)
		if mv["type"] == "play":
			var o := {}
			if mv.has("group") and mv["group"][0].rank == Card.Rank.R8 and player_count > 2 and mv["group"].size() > 1:
				o["distribute_eights"] = False
			_play_group(mv["group"], mv.get("declare", -1), o)
		else:
			on_draw_pressed()

func _group_by_rank(cards: Array[Card]) -> Array:
	if cards.is_empty(): return []
	var r = cards[0].rank
	for c in cards:
		if c.rank != r: return []
	return [cards]
