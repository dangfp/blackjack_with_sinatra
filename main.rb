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

  def winner!(message)
    @winner = "#{session[:player_name]} win!#{message}"
    @show_hit_and_stay_buttons = false
    session[:player_chip] += session[:player_betting]
  end

  def loser!(message)
    @loser = "Dealer win!#{message}"
    @show_hit_and_stay_buttons = false
    session[:player_chip] -= session[:player_betting]
  end

  def tie!(message)
    @winner = "It's tie.#{message}"
  end
end


get '/' do
  if session[:player_name]
    redirect '/player_betting'
  else
    erb :new_player
  end
end

get '/new_player' do
  if session[:player_name]
    redirect '/player_betting'
  else
    erb :new_player
  end
end

post '/new_player' do
  if params[:player_name].strip.empty?
    @error = "name must input!"
    halt erb(:new_player)
  else
    session[:player_name] = params[:player_name]
    redirect '/player_betting'
  end
end

get '/player_betting' do
  session[:player_chip] ||= 500

  if session[:player_chip] != 0
    erb :player_betting
  else
    redirect '/game_over'
  end
end

post '/player_betting' do
  player_betting = params[:player_betting].to_i
  if player_betting >= 1 && player_betting <= session[:player_chip]
    session[:player_betting] = player_betting
    redirect '/game'
  else
    @error = "Bet must in 1~#{session[:player_chip]}"
    halt erb(:player_betting)
  end
end

get '/game' do
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
    winner!("#{session[:player_name]} hit BlackJack!")
  elsif session[:player_total] > 21
    loser!("#{session[:player_name]} busted.")
  elsif session[:dealer_total] == 21
    loser!("Dealer hit BlackJack.")
  elsif session[:dealer_total] > 21
    winner!("Dealer busted.")
  else
    @show_hit_and_stay_buttons = true
  end
  
  erb :game
end

post '/game/player/hit' do
  @show_hit_and_stay_buttons = true

  session[:player_cards] << session[:deck].pop
  session[:player_total] = calculate_total(session[:player_cards])

  if session[:player_total] == 21
    winner!("#{session[:player_name]} hit BlackJack!")
  elsif session[:player_total] > 21
    loser!("#{session[:player_name]} busted.")
  end

  erb :game, layout: false
end

post '/game/player/stay' do
  @show_hit_and_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  while session[:dealer_total] < 17
    session[:dealer_cards] << session[:deck].pop
    session[:dealer_total] = calculate_total(session[:dealer_cards])

    if session[:dealer_total] == 21
      loser!("Dealer hit BlackJack.")
    elsif session[:dealer_total] > 21
     winner!("Dealer busted.")
    end
  end

  if session[:dealer_total] < 21
    redirect '/game/compare'
  else
    erb :game, layout: false
  end
end

get '/game/compare' do
  if session[:player_total] > session[:dealer_total]
    winner!("#{session[:player_name]}'total(#{session[:player_total]}) greater-than dealer's total(#{session[:dealer_total]}).")
  elsif session[:player_total] < session[:dealer_total]
    loser!("#{session[:player_name]}'total(#{session[:player_total]}) less-than dealer's total(#{session[:dealer_total]}).")
  else
    tie!("Both total are #{session[:player_total]}.")
  end

  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end




