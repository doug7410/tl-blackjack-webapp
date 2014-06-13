require 'rubygems'
require 'sinatra' 

set :sessions, true

BLACKJACK_AMT = 21
DEALER_STAY_AMT = 17

helpers do
  def calc_cards(hand)
    total = 0 #start of with 0
    hand.map do |card|
    card_value = card.first
      if card_value.to_i > 0 # if the card is a number
        total += card_value
      elsif card_value == "jack" || card_value == "queen" || card_value == "king" #if the card is a jack, queen, or king
        total += 10
      elsif card_value == "ace"
        total += 11
      end

      #correct for aces
      if card_value == "ace" and total > BLACKJACK_AMT
        total -= 10
      end

    end 
    total
  end

  def card_imgs(deck)
    deck.map do |card|
      card.push("#{card[1]}_#{card[0]}.jpg")
    end
  end

  def add_winnings
    winnings = session[:bet_ammount].to_i * 2
    session[:player_money] += winnings
    winnings
  end

  def deduct_bet
    session[:player_money] -= session[:bet_ammount].to_i
  end

  def give_back_bet
    session[:player_money] += session[:bet_ammount].to_i
  end

  def blackjack_or_bust_msg(hand)
    if calc_cards(hand) > BLACKJACK_AMT
      "Bust!"
    elsif calc_cards(hand) == BLACKJACK_AMT
      "Blackjack!"
    end
  end

  def loser!(msg) 
    @loser = "<strong>Sorry #{session[:username]}. #{msg}. </strong> You lost. Better luck next time."
  end

  def winner!(msg)
    winnings = session[:bet_ammount].to_i * 2
    session[:player_money] += winnings
    @winner = "<strong>Congratulations #{session[:username]}. #{msg}</strong> You win!"
  end

  def push!
    session[:player_money] += session[:bet_ammount].to_i
    @winner = "It's a push. You get your bet back."
  end

end

get '/' do
  session[:player_money] = 500
  session[:username] = nil
  session[:round] = 0
  if session[:username]
  	redirect '/game'
  else
   redirect '/username_form'
  end
end

get '/username_form' do
  @show_modal = true
  @username_form = true
  @bet_form = false
  if session[:username_missing]
    @input_error = "Please enter your name."
  end
	erb :game
end

post '/set_username' do
	name = params[:username]

  if name == ''
    session[:username_missing] = true
    redirect '/username_form'
  else
    session[:username] = name
    session[:username_missing] = false
	  redirect '/bet'
  end
end

get '/bet' do
  @show_modal = true
  @bet_form = true
  @username_form = false
  erb :game
end

post '/place_bet' do
  bet = params[:bet_ammount].to_i
  
  #error checking for bet form
  if !bet || bet <= 0 || bet > session[:player_money]
    @input_error = "Plese enter a number between 1 and #{session[:player_money]}"
    @bet_form = true
    @show_modal = true
    erb :game
  else
    session[:bet_ammount] = bet
    deduct_bet  
    redirect '/game'
  end
end

before do
  @show_hit_stay_buttons = true
end

get '/game' do
  session[:round] += 1
  cards = [2, 3, 4, 5, 6, 7, 8, 9, 10, "jack", "queen", "king", "ace"]
  suits = ["hearts", "diamonds", "clubs", "spades"]
  session[:deck] = card_imgs(cards.product(suits).shuffle)
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  @player_total = calc_cards(session[:player_hand])

  if @player_total == 21 
    winner!('You have Blackjack!')
    #add_winnings
    @show_hit_stay_buttons = false
  end

  erb :game
end

post '/game/player/hit' do
  # deal player a card
    session[:player_hand] << session[:deck].pop
    @player_total = calc_cards(session[:player_hand])

  if @player_total > BLACKJACK_AMT  # bust 
    @show_hit_stay_buttons = false
    loser!('You busted')
  elsif @player_total == BLACKJACK_AMT # hit blackjack
    @show_hit_stay_buttons = false
    winner!('You have Blackjack!') 
    #add_winnings
  end

  #go back to the game template
  erb :game, layout: false

end

post '/game/player/stay' do
  redirect '/dealer_turn'
end

get '/dealer_turn' do
  @show_hit_stay_buttons = false
  @dealer_total = calc_cards(session[:dealer_hand])
  if @dealer_total == BLACKJACK_AMT
    loser!("The dealer win with #{BLACKJACK_AMT}")
  elsif @dealer_total >= DEALER_STAY_AMT and @dealer_total < BLACKJACK_AMT
    @dealer_turn = false
    redirect '/compare_hands'
  elsif @dealer_total > BLACKJACK_AMT
    @dealer_turn = false
    winner!("The dealer busted.")
    #add_winnings
  else
    @dealer_turn = true
  end
  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_hand] << session[:deck].pop
  redirect '/dealer_turn'
end

get '/compare_hands' do
  @dealer_total = calc_cards(session[:dealer_hand])
  @player_total = calc_cards(session[:player_hand])
  @dealer_turn = false
  @show_hit_stay_buttons = false

  if @dealer_total > @player_total
    loser!("The dealer wins with #{calc_cards(session[:dealer_hand])}")
  elsif @dealer_total < @player_total
    winner!("You beat the dealer with #{calc_cards(session[:player_hand])}.")
    #add_winnings
  else
    push!
  end

  erb :game, layout: false
end

get '/game/over' do
  erb :game_over
end

get '/play_again' do
  session[:player_money] = 500
  redirect '/bet'
end