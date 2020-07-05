extends Node2D

const CARD_SUIT = ["clubs", "diamonds", "hearts", "spades"]
const CARD_VALUE = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]
enum {PLAYER, DEALER}

var screen_size

var deck = []
var player_hand = []
var dealer_hand = []

var player_hit = false
var dealer_hit = false
var player_stand = false
var dealer_stand = false
var game_ended = false

func reset_deck():
	deck.clear()
	for current_suit in CARD_SUIT.size():
		for current_value in CARD_VALUE.size():
			var current_card = {
				"Suit" : CARD_SUIT[current_suit],
				"Value" : CARD_VALUE[current_value]
			}
			deck.append(current_card)

func deal_card(draw_number : int, target_hand : Array):
	for i in draw_number:
		target_hand.append(deck[0])
		deck.remove(0)

func check_hand(target_player : int):
	var target_hand
	var target_node
	var target_handvalue
	var ace_count = 0
	match target_player:
		PLAYER:
			target_hand = player_hand
			target_node = $PlayerHand
			target_handvalue = $Buttons/HandValue
		DEALER:
			target_hand = dealer_hand
			target_node = $DealerHand
			target_handvalue = $Buttons/DealerHand
	var hand_value : int = 0
	for i in target_hand.size():
		hand_value += convert_card(target_hand[i].Value)
		if target_hand[i].Value == "ace":
			ace_count += 1
	
	while ace_count:
		if hand_value > 21:
			hand_value -= 10
			ace_count -= 1
		else:
			break
	
	target_handvalue.text = "Hand: " + str(hand_value)
	
	if hand_value < 16:
		if target_player == PLAYER:
			$Buttons/StandButton.visible = false
	elif hand_value >= 16 and hand_value < 21:
		if target_player == PLAYER:
			$Buttons/HitButton.visible = true
			$Buttons/StandButton.visible = true
	elif hand_value == 21:
		match target_player:
			PLAYER:
				if !player_hit:
					blackjack(target_player)
				else:
					$Buttons/HitButton.visible = false
					$Buttons/StandButton.visible = true
			DEALER:
				if !dealer_hit:
					blackjack(target_player)
	else:
		bust(target_player, hand_value)
	return hand_value

func convert_card(card : String):
	var value : int
	match card:
		"ace":
			value = 11
		"2":
			value = 2
		"3":
			value = 3
		"4":
			value = 4
		"5":
			value = 5
		"6":
			value = 6
		"7":
			value = 7
		"8":
			value = 8
		"9":
			value = 9
		"10", "Jack", "Queen", "King":
			value = 10
	return value

func update_cards(target_player : int):
	var target_hand
	var target_node
	match target_player:
		PLAYER:
			target_hand = player_hand
			target_node = $PlayerHand
		DEALER:
			target_hand = dealer_hand
			target_node = $DealerHand
	for i in target_hand.size():
		var path = "res://sprites/cards/"
		path += target_hand[i].Value
		path += " of "
		path += target_hand[i].Suit
		path += ".png"
		var new_position = Vector2()
		new_position.x = -32 * i
		var current_card = TextureRect.new()
		current_card.texture = load(path)
		current_card.rect_global_position = new_position
		target_node.add_child(current_card)

func end_game(msg : String):
	game_ended = true
	$Buttons/DealButton.visible = true
	$Buttons/HandValue.visible = false
	$Buttons/HitButton.visible = false
	$Buttons/StandButton.visible = false
	$Buttons/Message.visible = true
	$Buttons/Message.text = msg

func blackjack(target_player: int):
	match target_player:
		PLAYER:
			end_game("PLAYER BLACKJACK!")
		DEALER:
			end_game("DEALER BLACKJACK!")

func bust(target_player : int, hand_value : int):
	match target_player:
		PLAYER:
			end_game("Player Bust! Hand value: " + str(hand_value))
		DEALER:
			end_game("Dealer Bust!")

func showdown():
	if game_ended:
		return
	var player_score = check_hand(PLAYER)
	var dealer_score = check_hand(DEALER)
	if player_score > dealer_score and player_score <= 21:
		end_game("Player wins!")
	elif dealer_score > player_score and dealer_score <= 21:
		end_game("Dealer wins!")
	elif player_score == dealer_score:
		end_game("Draw!")
	else:
		end_game("WTF?")

func reset_hands():
	player_hit = false
	dealer_hit = false
	player_stand = false
	dealer_stand = false
	player_hand.clear()
	dealer_hand.clear()
	for child in $PlayerHand.get_children():
		child.queue_free()
	for child in $DealerHand.get_children():
		child.queue_free()

func starting_deal():
	for i in 2:
		deal_card(1, player_hand)
		deal_card(1, dealer_hand)

func dealer_play():
	if check_hand(DEALER) >= 16:
		if check_hand(DEALER) >= check_hand(PLAYER):
			dealer_stand = true
		if check_hand(PLAYER) > 21:
			dealer_stand = true
	if game_ended or dealer_stand:
		return
	
	dealer_hit = true
	deal_card(1, dealer_hand)
	update_cards(DEALER)
	check_hand(DEALER)
	

func _ready():
	randomize()
	screen_size = get_viewport_rect().size
	$PlayerHand.offset.y = screen_size.y - 5 - 32
	$PlayerHand.offset.x = screen_size.x - 32
	$DealerHand.offset.x = screen_size.x - 32
	$Buttons/DealerHand.visible = false
	$Buttons/HitButton.visible = false
	$Buttons/HandValue.visible = false
	$Buttons/StandButton.visible = false


func _on_HitButton_pressed():
	player_hit = true
	deal_card(1, player_hand)
	update_cards(PLAYER)
	check_hand(PLAYER)
	if !dealer_stand:
		dealer_play()


func _on_DealButton_pressed():
	game_ended = false
	reset_deck()
	reset_hands()
	deck.shuffle()
	starting_deal()
	$Buttons/DealButton.visible = false
	$Buttons/HitButton.visible = true
	$Buttons/StandButton.visible = true
	$Buttons/HandValue.visible = true
	$Buttons/Message.visible = false
	$Buttons/DealerHand.visible = true
	update_cards(PLAYER)
	update_cards(DEALER)
	check_hand(PLAYER)
	check_hand(DEALER)
	

# TODO: DEALER AI
func _on_StandButton_pressed():
	while !dealer_stand and !game_ended:
		dealer_play()
	showdown()
