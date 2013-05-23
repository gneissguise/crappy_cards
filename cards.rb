class Deck
  RANKS = %w(Ace 2 3 4 5 6 7 8 9 10 Jack Queen King)
  SUITS = %w(Clubs Diamonds Hearts Spades)

  attr_accessor :cards

  def initialize
    self.cards = []
    SUITS.each do |suit|
      RANKS.each do |rank|
        self.cards << {:rank => rank, :suit => suit}
      end
    end
  end

  def shuffle_deck
    self.cards.shuffle!
  end

  def deal
    self.cards.pop
  end

  def merge(hand)
    hand.each{ |card| self.cards << card }
  end
end

class Game
  def initialize
    @deck = Deck.new    
    @p = { :player => [], :dealer => [] }
    @discard = []
  end

  def shuffle_cards
    if @p[:player].count > 0
      @deck.merge(@p[:player])
      @deck.merge(@p[:dealer])
      @p.clear
    end

    if @discard.count > 0
      @deck.merge(@discard)
      @discard.clear
    end

    @deck.shuffle_deck
    puts "Card deck shuffled."
  end

  def deal_cards(c)
    (c * 2 ).times do |i| 
      i % 2 == 0 ? @p[:player] << @deck.deal : @p[:dealer] << @deck.deal
    end
    puts "Dealt #{c} cards."
  end

  def deal_card(c, player)
    c.times{ @p[player] << @deck.deal }
    puts "Dealt #{c} card#{c != 1 ? 's' : ''}."
  end

  def show_hand(player)
    unless empty_hand? 
      puts "#{player == :player ? 'Your hand:' : 'Dealers hand:'}"
      @p[player].each_with_index do |card, x| 
        puts "[#{x}] #{card[:rank]} of #{card[:suit]}"
      end
    end
  end

  def prompt
    print "Command? > "
  end

  def get_action
    @action = gets.chomp()
  end

  def show_help
    puts "Help menu"
    puts "-" * 15
      
    @cmd_list.each{ |k, v| puts "#{k} - #{v}" }
  end

  def pop_card(cards, player)
    cards.sort.reverse.each do |card|
     @discard << @p[player].delete_at(card.to_i)
    end
  end

  def empty_hand?
    @p[:player].empty?
  end

  def discard_result(cmd, player)
    result = true
    cmd.gsub!(/\s+/, "")
    clist = cmd.split(',')
    clist.uniq!

    clist.each do |c|
      if c =~ /[^01234]/
        result = false
        break
      end
    end

    if result
      pop_card(clist, player)
      puts "Discarded cards: #{clist.join(', ')}"
      deal_card(clist.length, player)
    else
      puts "Please enter a valid card index"
      puts "(multiple indexes may be separated by commas)"
    end

    return result
  end

  def discard(player)
    empty_hand? ? discarded = true : discarded = false
    until discarded do
      print "Which cards to discard? > "
      cmd = gets.chomp

      case cmd.downcase
      when "help"
        puts "Enter one or more card index separated by comma, or type 'none'."
      when "none" 
        break
      else
       discarded = discard_result(cmd, player)
      end
    end
  end

  def flush?(player)
    suit_comp = []
    @p[player].each { |card| suit_comp << card[:suit] }
    suit_comp.uniq!
    if suit_comp.count == 1
      return true
    else
      return false
    end
  end

  def hand_value(player)
    rank_comp = []
    card_val = { "Ace" => 1, 
                 "2" => 2, 
                 "3" => 3, 
                 "4" => 4,
                 "5" => 5, 
                 "6" => 6, 
                 "7" => 7, 
                 "8" => 8,
                 "9" => 9, 
                 "10" => 10, 
                 "Jack" => 11,
                 "Queen" => 12,
                 "King" => 13 }
    @p[player].each { |card| rank_comp << card_val[card[:rank]] }  

    rank_comp.sort!
    
    if rank_comp.join(',') == "1,10,11,12,13"
      rank_comp[0] = 14
      rank_comp.sort!
    end

    return rank_comp
  end

  def straight?(player)
    rank_comp = []
    rank_comp = hand_value(player)

    return rank_comp.each_cons(2).all? { |x, y| y == x + 1}
  end

  def ace_high?(player)
    rank_comp = []
    rank_comp = hand_value(player)
    if rank_comp[4] == 14
      return true
    else
      return false
    end
  end

  def has_set?(player, set_amt)
    rank_comp = []
    rank_comp = hand_value(player)

    rank_comp.detect{ |x| rank_comp.count(x) == set_amt }
  end

  def two_pairs?(player)
    rank_comp = []
    rank_comp = hand_value(player)

    rank_comp = rank_comp.select{ |x| rank_comp.count(x) == 2}.uniq

    if rank_comp == 2 
      return true
    else
      return false
    end
  end

  def tie_break(player, p_hand, dealer, d_hand)
    p = []
    d = []

    p = hand_value(player)
    d = hand_value(dealer)

    if p[4] > d[4] 
      d_hand -= 1
    else
      p_hand -= 1
    end

    return p_hand, d_hand
  end

  def high_card(player)
    rank_comp = []
    rank_comp = hand_value(player)

    return rank_comp[4]
  end

  def compare_hands
    #Hand ranking:
    #Royal Flush 10
    if flush?(:player) and straight?(:player) and ace_high?(:player) and p_hand.nil?
      puts "Player has a royal flush."
      p_hand = 10
    end
    if flush?(:dealer) and straight?(:dealer) and ace_high?(:dealer) and d_hand.nil?
      puts "Dealer has a royal flush."
      d_hand = 10
    end

    #Straight Flush 9
    if flush?(:player) and straight?(:player) and p_hand.nil?
      puts "Player has a straight flush."
      p_hand = 9
    end
    if flush?(:dealer) and straight?(:dealer) and d_hand.nil?
      puts "Dealer has a straight flush."
      d_hand = 9
    end 
    
    #Four of a Kind 8
    if has_set?(:player, 4) and p_hand.nil?
      puts "Player has a four of a kind."
      p_hand = 8
    end
    if has_set?(:dealer, 4) and d_hand.nil?
      puts "Dealer has a four of a kind."
      d_hand = 8
    end

    #Full House 7
    if has_set?(:player, 3) and has_set?(:player, 2) and p_hand.nil?
      puts "Player has a full house."
      p_hand = 7
    end
    if has_set?(:dealer, 3) and has_set?(:dealer, 2) and d_hand.nil?
      puts "Dealer has a full house."
      d_hand = 7
    end

    #Flush 6
    if flush?(:player) and p_hand.nil?
      puts "Player has a flush."
      p_hand = 6
    end
    if flush?(:dealer) and d_hand.nil?
      puts "Dealer has a flush."
      p_hand = 6
    end
    
    #Straight 5
    if straight?(:player) and p_hand.nil?
      puts "Player has a straight."
      p_hand = 5
    end
    if straight?(:dealer) and d_hand.nil?
      puts "Dealer has a straight."
      p_hand = 5
    end
    
    #Three of a Kind 4
    if has_set?(:player, 3) and p_hand.nil?
      puts "Player has a three of a kind."
      p_hand = 4
    end
    if has_set?(:dealer, 3) and d_hand.nil?
      puts "Dealer has a three of a kind."
      d_hand = 4
    end

    #Two Pair 3
    if two_pairs?(:player) and p_hand.nil?
      puts "Player has two pairs."
      p_hand = 3
    end
    if two_pairs?(:dealer) and d_hand.nil?
      puts "Dealer has two pairs."
      d_hand = 3
    end

    #One Pair 2
    if has_set?(:player, 2) and p_hand.nil?
      puts "Player has a pair."
      p_hand = 2
    end
    if has_set?(:dealer, 2) and d_hand.nil?
      puts "Dealer has a pair."
      d_hand = 2
    end

    #High Card 1
    if p_hand.nil?
      puts "Player high card: #{high_card(:player)}"
      p_hand = 1
    end
    if d_hand.nil?
      puts "Dealer high card: #{high_card(:dealer)}"
      d_hand = 1
    end
    
    if p_hand == d_hand
      p_hand, d_hand = tie_break(:player, p_hand, :dealer, d_hand)
    end

    if p_hand > d_hand 
      puts "Player has won!"
    else
      puts "Dealer has won!"
    end
  end

  def draw
    #Todo: add dealer AI sometime
    show_hand(:dealer)
    show_hand(:player)
    compare_hands
  end

  def return_action
    @action.downcase!

    @cmd_list = {"help" => "Returns a list of commands [this menu].",
                 "shuffle" => "Shuffles the deck.",
                 "deal" => "Deals cards.",
                 "discard" => "Discards cards from your hand and deals new cards.",
                 "draw" => "Action goes to the dealer, then automatic showdown",
                 "quit" => "Exits the game."}
  
    case @action
    when "help"
      show_help
    when "shuffle"
      shuffle_cards
    when "deal"
      deal_cards(5)
      show_hand(:player)
    when "discard"
      discard(:player)
      show_hand(:player)
    when "draw"
      draw
    when "quit"
      quit
    else
      puts "Invalid command."
    end
  end

  def play
    puts "\r\nWelcome to my crappy card game."
    puts "Type help at the prompt for a list of commands.\r\n\r\n"

    while true
      prompt
      get_action
      return_action
    end
  end

  def quit
    puts "Goodbye."
    Process.exit(1)
  end
end

my_game = Game.new
my_game.play