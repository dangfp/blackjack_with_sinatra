require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def calculate_total(cards)
    array = cards.map {|card| card[1]}
    total = 0

    array.each do |value|
      if value == 'A'
        total += 11
      elsif value == 'J' || value == 'Q' || value == 'K'
        total += 10
      else
        total += value.to_i
      end
    end

    # correct for A
    array.select{|value| value == 'A'}.count.times do
      if total > 21
        total -= 10
      end
    end

    total
  end

  def show_card_image(card)
    suit = case card[0]
      when 'C' then 'clubs'
      when 'D' then 'diamonds'
      when 'H' then 'hearts'
      when 'S' then 'spades'
    end

    face_value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(face_value)
      face_value = case card[1]
      when 'A' then 'ace'
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      end
    end

    "<img src='/images/cards/#{suit}_#{face_value}.jpg' class='card_image'>"
  end

  def player_turn
    session[:player_cards] << session[:deck].pop
    session[:player_total] = calculate_total(session[:player_cards])

    if session[:player_total] == 21
      @success = "#{session[:player_name]} hit BlackJack, you win!"
      @show_hit_and_stay_buttons = false
    elsif session[:player_total] > 21
      @error = "#{session[:player_name]} busts, dealer win!"
      @show_hit_and_stay_buttons = false
    end
  end

  def dealer_turn
    while session[:dealer_total] < 17
      session[:dealer_cards] << session[:deck].pop
      session[:dealer_total] = calculate_total(session[:dealer_cards])

      if session[:dealer_total] == 21
        @error = "Dealer hit BlackJack, dealer win!"
      elsif session[:player_total] > 21
        @success = "Dealer busts, #{session[:player_name]} win!"
      end
    end
  end

  def compare
    if session[:player_total] > session[:dealer_total]
      @success = "#{session[:player_name]} win!"
    elsif session[:player_total] < session[:dealer_total]
      @error = "Dealer win!"
    else
      @success = "It's tie."
    end
  end
end


get '/' do
  if session[:player_name]
    redirect '/game'
  else
    erb :new_player
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].strip.empty?
    @error = "name must input!"
    erb :new_player
  else
    session[:player_name] = params[:player_name]
    redirect '/game'
  end
  
end


get '/game' do

  session[:player_chip] = 500 if session[:player_chip] == nil

  suits = ['H', 'D', 'S', 'C']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(cards).shuffle!

  session[:player_cards] = []
  session[:dealer_cards] = []
  2.times do
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  end

  session[:player_total] = calculate_total(session[:player_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])

  if session[:player_total] == 21
    @success = "#{session[:player_name]} hit BlackJack, you win!"
  elsif session[:player_total] > 21
    @error = "#{session[:player_name]} busts, dealer win!"
  elsif session[:dealer_total] == 21
    @error = "Dealer hit BlackJack, dealer win!"
  elsif session[:dealer_total] > 21
    @success = "Dealer busts, #{session[:player_name]} win!"
  else
    @show_hit_and_stay_buttons = true
  end

  @current_turn = 'player'
  erb :game
end

post '/game/player_hit' do
  @show_hit_and_stay_buttons = true
  player_turn
  erb :game
end

post '/game/player_stay' do
  @show_hit_and_stay_buttons = false
  @current_turn = 'dealer'
  dealer_turn
  compare if session[:dealer_total] < 21
  erb :game
end






