class_name Card

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }
enum Rank { R6 = 6, R7 = 7, R8 = 8, R9 = 9, R10 = 10, JACK = 11, QUEEN = 12, KING = 13, ACE = 14 }

var suit: int
var rank: int

func _init(_suit: int, _rank: int):
	suit = _suit
	rank = _rank

func is_jack() -> bool: return rank == Rank.JACK
func is_queen_spades() -> bool: return rank == Rank.QUEEN and suit == Suit.SPADES
func is_six() -> bool: return rank == Rank.R6
func is_seven() -> bool: return rank == Rank.R7
func is_eight() -> bool: return rank == Rank.R8
func is_ace() -> bool: return rank == Rank.ACE

func rank_label() -> String:
	match rank:
		Rank.JACK: return "В"
		Rank.QUEEN: return "Д"
		Rank.KING: return "К"
		Rank.ACE: return "Т"
		_: return str(rank)

func suit_symbol() -> String:
	match suit:
		Suit.CLUBS: return "♣"
		Suit.DIAMONDS: return "♦"
		Suit.HEARTS: return "♥"
		Suit.SPADES: return "♠"
		_: return "?"
