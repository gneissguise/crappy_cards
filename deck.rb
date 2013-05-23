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