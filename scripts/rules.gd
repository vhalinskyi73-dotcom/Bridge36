extends Node
class_name Rules

# Стан правил
var requested_suit: int = -1            # після валета; -1 = немає
var must_cover_self: bool = false       # активне "накрий сам" після зіграної 6
var pending_draw: int = 0               # акумульований добір на наступного (стекінг)
var pending_skips: int = 0              # акумульовані пропуски (стекінг)
var pending_queue: Array = []           # черга походових ефектів (для розподілу 8-ок): [{draw:int, skips:int}]

func reset_round_state():
	requested_suit = -1
	must_cover_self = false
	pending_draw = 0
	pending_skips = 0
	pending_queue.clear()

func can_play_group(group: Array[Card], top: Card) -> bool:
	if group.is_empty(): return false
	# 1) усі одного рангу
	for i in range(1, group.size()):
		if group[i].rank != group[0].rank: return false
	var r = group[0].rank
	var first = group[0]
	if r == Card.Rank.JACK:
		return true # валет на все
	var suit_to_match = requested_suit if requested_suit != -1 else top.suit
	if r == top.rank:
		return true
	if first.suit == suit_to_match:
		return true
	return false

# opts: {"distribute_eights": bool}
func apply_effects_after_play(group: Array[Card], opts: Dictionary = {}):
	var last: Card = group[-1]
	var r = group[0].rank

	if r == Card.Rank.JACK:
		# замовлення масті задається з UI через requested_suit
		pass
	elif r == Card.Rank.R7:
		pending_draw += group.size() * 1
	elif r == Card.Rank.R8:
		var distribute := false
		if opts.has("distribute_eights"):
			distribute = bool(opts["distribute_eights"])    
		if distribute and group.size() > 1:
			for i in range(group.size()):
				pending_queue.append({"draw": 2, "skips": 1})
		else:
			pending_draw += group.size() * 2
			pending_skips += group.size()
	elif r == Card.Rank.ACE:
		pending_skips += group.size()
	elif r == Card.Rank.QUEEN:
		# Ефект лише якщо верхня карта саме Q♠
		if last.is_queen_spades():
			pending_draw += 5

	# Після будь-якого ходу: якщо верх стосу = 6 → гравець мусить накрити в свій хід
	must_cover_self = last.is_six()

func settle_start_of_turn_state() -> Dictionary:
	# Спочатку обслуговуємо чергу (розподіл 8-ок). Якщо її немає — застосовуємо акумулятори.
	if not pending_queue.is_empty():
		var eff = pending_queue.pop_front()
		return eff
	var out = {"draw": pending_draw, "skips": pending_skips}
	pending_draw = 0
	pending_skips = 0
	return out

func clear_requested_suit_if_matched(played_group_last: Card, top_after: Card) -> void:
	if requested_suit == -1:
		return
	if played_group_last.suit == requested_suit:
		requested_suit = -1

# Підрахунок очок у руці після раунду
static func hand_points(hand: Array[Card]) -> int:
	if hand.is_empty():
		return 0
	var only_jacks := true
	for c in hand:
		if c.rank != Card.Rank.JACK:
			only_jacks = false
			break
	var sum := 0
	for c in hand:
		match c.rank:
			Card.Rank.R10: sum += 10
			Card.Rank.JACK:
				sum += 20 if only_jacks else 10
			Card.Rank.QUEEN:
				sum += 50 if c.is_queen_spades() else 10
			Card.Rank.KING: sum += 10
			Card.Rank.ACE: sum += 15
			_: pass
	return sum
