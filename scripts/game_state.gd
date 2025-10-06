extends Node
class_name GameState

const MAX_PLAYERS := 4

var players: Array = []                  # {hand:Array[Card], is_bot:bool, score:int}
var current_idx: int = 0
var deck: Deck
var discard: Array[Card] = []
var rules: Rules

var last_play_group: Array[Card] = []

func _ready():
	deck = Deck.new()
	rules = Rules.new()

func start_match(player_count: int = 2, bot_mask: Array[bool] = []):
	players.clear()
	for i in range(player_count):
		players.append({"hand": [], "is_bot": bot_mask.size() > i ? bot_mask[i] : true, "score": 0})
	current_idx = 0

func start_round():
	deck.build_36()
	deck.shuffle()
	rules.reset_round_state()
	discard.clear()
	last_play_group.clear()

	# роздача: кожному по 5, роздавачу 4 + 5-та у відбій відкритою
	for _i in range(5):
		for i in range(players.size()):
			var receive = (i == current_idx and _i == 4) ? false : true
			if receive:
				var d = deck.draw_one()
				if d != null:
					players[i].hand.append(d)
			elif i == current_idx and _i == 4:
				var starter = deck.draw_one()
				if starter != null:
					discard.append(starter)
					# Стартова 6 не активує must_cover_self

	for p in players:
		p.hand = p.hand.filter(func(x): return x != null)

func top_card() -> Card:
	return discard.is_empty() ? null : discard[-1]

func legal_groups_for_hand(hand: Array[Card]) -> Array:
	var groups: Array = []
	var top = top_card()
	if top == null:
		return groups
	var by_rank: Dictionary = {}
	for c in hand:
		var arr: Array = by_rank.get(c.rank, [])
		arr.append(c)
		by_rank[c.rank] = arr
	for rank in by_rank.keys():
		var arr_cards: Array = by_rank[rank]
		arr_cards.sort_custom(func(a, b): return a.suit < b.suit)
		for k in range(1, min(4, arr_cards.size()) + 1):
			var candidate := arr_cards.slice(0, k)
			if rules.can_play_group(candidate, top):
				groups.append(candidate)
	return groups

func play_group(player_idx: int, group: Array[Card], declared_suit: int = -1, opts: Dictionary = {}):
	for c in group:
		var idx = players[player_idx].hand.find(c)
		if idx != -1:
			players[player_idx].hand.remove_at(idx)
	for c in group:
		discard.append(c)
	if group[0].is_jack() and declared_suit != -1:
		rules.requested_suit = declared_suit
	rules.apply_effects_after_play(group, opts)
	rules.clear_requested_suit_if_matched(group[-1], top_card())
	last_play_group = group.duplicate(true)

func draw_cards(player_idx: int, n: int) -> void:
	for i in range(n):
		var c = deck.draw_one()
		if c == null:
			if discard.size() > 1:
				var top_keep = discard.pop_back()
				var new_cards = discard.duplicate(true)
				discard.clear()
				discard.append(top_keep)
				new_cards.shuffle()
				for nc in new_cards:
					deck.cards.append(nc)
				c = deck.draw_one()
		if c != null:
			players[player_idx].hand.append(c)

func end_of_turn_advance() -> void:
	current_idx = (current_idx + 1) % players.size()

func process_start_of_turn():
	var eff = rules.settle_start_of_turn_state()
	var draw_n = int(eff.get("draw", 0))
	var skip_n = int(eff.get("skips", 0))
	if draw_n > 0:
		draw_cards(current_idx, draw_n)
	if skip_n > 0:
		for i in range(skip_n):
			end_of_turn_advance()

func is_round_over() -> bool:
	for p in players:
		if p.hand.is_empty():
			return true
	return false

func winner_of_round_index() -> int:
	for i in range(players.size()):
		if players[i].hand.is_empty():
			return i
	return -1

func settle_round_scores() -> void:
	var finisher = winner_of_round_index()
	for i in range(players.size()):
		if i == finisher: continue
		players[i].score += Rules.hand_points(players[i].hand)
		if players[i].score == 125:
			players[i].score = 0
	var only_jacks_finish := true
	for c in last_play_group:
		if c.rank != Card.Rank.JACK:
			only_jacks_finish = false
			break
	if finisher != -1 and only_jacks_finish and last_play_group.size() > 0:
		players[finisher].score -= 20 * last_play_group.size()

func has_match_loser() -> int:
	for i in range(players.size()):
		if players[i].score > 125:
			return i
	return -1
