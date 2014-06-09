require 'rubygems'
require 'sinatra' 

set :sessions, true

helpers do
  def calc_cards(hand)
    total = 0 #start of with 0
    hand.map do |card|
    card_value = card.first
      if card_value.to_i > 0 # if the card is a number
        total += card_value
      elsif card_value == "jack" || card_value == "queen" || card_value == "king" #if the card is a jack, queen, or king
        total += 10
      elsif card_value == "ace" && total > 10
        total += 1
      elsif card_value == "ace" && total <= 10  
        total += 11
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
end

get '/' do
  session[:player_money] = 500
  session[:username] = nil
  if session[:username]
  	redirect '/game'
  else
   redirect '/username_form'
  end
end

get '/username_form' do
	erb :username_form
end

post '/set_username' do
	session[:username] = params[:username]
	redirect '/bet'
end

get '/bet' do
  erb :bet_form
end

post '/place_bet' do
  session[:bet_ammount] = params[:bet_ammount].to_i
  deduct_bet
  redirect '/game'
end

before do
  @show_hit_stay_buttons = true
end

get '/game' do
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
    @success = "Congrats #{session[:username]}! You have blackjack!"
    @show_hit_stay_buttons = false
  end
  erb :game
end

post '/game/player/hit' do
  # deal player a card
    session[:player_hand] << session[:deck].pop
    # get the new total
    @player_total = calc_cards(session[:player_hand])

  if @player_total > 21  # bust 
    @show_hit_stay_buttons = false
    @error = "Bust!"
    deduct_bet
    #redirect '/end_game'
  elsif @player_total == 21 # hit blackjack
    @show_hit_stay_buttons = false
    @success = "blackjack!"
    add_winnings
    #session[:player_money] += (session[:bet_ammount].to_i * 2)
    #redirect '/end_game'
  end

  #go back to the game template
  erb :game

end

post '/game/player/stay' do
    redirect '/dealer_turn'
end

get '/dealer_turn' do
  @show_hit_stay_buttons = false
  @dealer_total = calc_cards(session[:dealer_hand])
  if @dealer_total == 21
    @error = "Sorry, the dealer has blackjack. You loose."
  elsif @dealer_total > 16 and @dealer_total < 21
    @dealer_turn = false
    redirect '/compare_hands'
  elsif @dealer_total > 21
    @dealer_turn = false
    @success = "The dealer bust! You win!"
    add_winnings
  else
    @dealer_turn = true
  end

  erb :game
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
    @error = "Sorry! The dealer wins this round."
  elsif @dealer_total < @player_total
    @success = "Congrats! You win this round."
    add_winnings
  else
    @success = "It looks like we have a tie"
    give_back_bet
  end

  erb :game
end