extends Node
class_name Deck

var cards: Array[Card] = []

func build_36():
	cards.clear()
	for s in [Card.Suit.CLUBS, Card.Suit.DIAMONDS, Card.Suit.HEARTS, Card.Suit.SPADES]:
		for r in [Card.Rank.R6, Card.Rank.R7, Card.Rank.R8, Card.Rank.R9, Card.Rank.R10, Card.Rank.JACK, Card.Rank.QUEEN, Card.Rank.KING, Card.Rank.ACE]:
			cards.append(Card.new(s, r))

func shuffle():
	cards.shuffle()

func draw_one() -> Card:
	if cards.is_empty():
		return null
	return cards.pop_back()

func put_under(c: Card) -> void:
	cards.push_front(c)
