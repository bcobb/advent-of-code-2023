class Card
  LABELS = %w[A K Q J T 9 8 7 6 5 4 3 2]
  RANKS_BY_LABEL = LABELS.reverse.map.with_index.to_h { |card, index| [card, index] }

  def initialize(label)
    @label = label
    @rank = RANKS_BY_LABEL[label]
    @pretend_label = nil
  end

  attr_reader :rank

  def label
    @pretend_label || @label
  end

  def joker?
    @label == "J"
  end

  def used?
    !@pretend_label.nil?
  end

  def joker!(other)
    if joker?
      @pretend_label = other.label
      @rank = -1
    end
  end
end

class Hand
  include Comparable

  def initialize(card_labels, bid, jokers_wild = false)
    @cards = card_labels.map { |label| Card.new(label) }
    @bid = bid

    if jokers_wild
      replacement = @cards.reject(&:joker?).group_by(&:label).values.sort_by(&:length).last&.first
      replacement ||= @cards.first

      @cards.select(&:joker?).each do |joker|
        joker.joker!(replacement)
      end
    end

    strength = @cards.map(&:label).tally.values.sort.reverse
    ranks = @cards.map(&:rank)

    @sort_key = [strength, ranks]
  end

  attr_reader :bid
  protected attr_reader(:sort_key)

  def <=>(other)
    self.sort_key <=> other.sort_key
  end
end

def line_to_hand(line, jokers_wild:)
  cards_string, bid_string = line.strip.split(" ")

  Hand.new(cards_string.chars, bid_string.to_i, jokers_wild)
end

def part_one(input)
  input.lines.map { |line| line_to_hand(line, jokers_wild: false) }.sort.each_with_index.reduce(0) do |sum, (hand, index)|
    rank = index + 1

    sum + (hand.bid * rank)
  end
end

def part_two(input)
  input.lines.map { |line| line_to_hand(line, jokers_wild: true) }.sort.each_with_index.reduce(0) do |sum, (hand, index)|
    rank = index + 1

    sum + (hand.bid * rank)
  end
end

def main
  puts("part one sample: #{part_one(File.read("inputs/seven.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/seven.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/seven.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/seven.txt"))}")
end

main if $0 == __FILE__
