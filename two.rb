class GameRecord
  def self.parse(lines)
    games = lines.map do |line|
      _, unparsed_revelations = line.split(": ")
      number = line.scan(/\d+/).first.to_i
      turns = unparsed_revelations.split(";").map do |revelation|
        parts = revelation.scan(/(\d+) (red|green|blue)/)

        Turn.new(parts.map { |quantity, color| [color, quantity.to_i] })
      end

      Game.new(number, turns)
    end

    new(games)
  end

  def initialize(games)
    @games = games
  end

  attr_reader :games
end

class Turn
  def initialize(revelations)
    @revelations = revelations
  end

  attr_reader :revelations

  def power_map
    @revelations.each_with_object({}) do |(color, count), map|
      map[color] ||= 0
      map[color] += count
    end
  end
end

class Game
  def initialize(number, turns)
    @bag = {
      "red" => 12,
      "green" => 13,
      "blue" => 14
    }
    @turns = turns
    @number = number
  end

  attr_reader :number
  attr_reader :turns

  def possible?
    @turns.all? do |turn|
      turn.revelations.each do |color, count|
        @bag[color] -= count
      end

      if @bag.any? { |_, value| value < 0 }
        false
      else
        turn.revelations.each do |color, count|
          @bag[color] += count
        end

        true
      end
    end
  end

  def power
    power_map = @turns.map(&:power_map).reduce do |turn_power_map_one, turn_power_map_two|
      turn_power_map_one.merge(turn_power_map_two) do |_, v1, v2|
        v1 > v2 ? v1 : v2
      end
    end

    power_map.values.reduce(&:*)
  end
end

def part_one(input)
  record = GameRecord.parse(input.lines)
  record.games.select(&:possible?).sum(&:number)
end

def part_two(input)
  record = GameRecord.parse(input.lines)
  record.games.sum(&:power)
end

def main
  puts("part one sample: #{part_one(File.read("inputs/two.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/two.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/two.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/two.txt"))}")
end

main if $0 == __FILE__
