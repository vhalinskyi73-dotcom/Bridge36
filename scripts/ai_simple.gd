extends Node
class_name AISimple

# Дуже базовий бот

func choose_move(gs: GameState, idx: int) -> Dictionary:
	var hand: Array[Card] = gs.players[idx].hand
	var groups = gs.legal_groups_for_hand(hand)
	if groups.is_empty():
		return {"type": "draw_or_pass"}
	# валет як універсальний хід
	for g in groups:
		if g[0].is_jack():
			var best_suit = most_common_suit(hand)
			return {"type": "play", "group": g, "declare": best_suit}
	# найдешевший сет
	groups.sort_custom(func(a, b): return group_cost(a) < group_cost(b))
	return {"type": "play", "group": groups[0], "declare": -1}

func most_common_suit(hand: Array[Card]) -> int:
	var cnt = {Card.Suit.CLUBS:0, Card.Suit.DIAMONDS:0, Card.Suit.HEARTS:0, Card.Suit.SPADES:0}
	for c in hand:
		cnt[c.suit] += 1
	var best = Card.Suit.CLUBS
	var bestv = -1
	for s in cnt.keys():
		if cnt[s] > bestv:
			bestv = cnt[s]
			best = s
	return best

func group_cost(g: Array[Card]) -> int:
	var sum := 0
	for c in g:
		match c.rank:
			Card.Rank.R10: sum += 10
			Card.Rank.JACK: sum += 10
			Card.Rank.QUEEN: sum += 50 if c.is_queen_spades() else 10
			Card.Rank.KING: sum += 10
			Card.Rank.ACE: sum += 15
			_: sum += 0
	return sum
