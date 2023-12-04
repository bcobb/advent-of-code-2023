def score(numbers)
  numbers.empty? ? 0 : 2 ** (numbers.length - 1)
end

def part_one(input)
  input
    .lines
    .sum do |line|
      card_input, _, winning_numbers_input, _, my_numbers_input = line
        .strip
        .split(/(: | \| )/)

      score(winning_numbers_input.split(/\s+/) & my_numbers_input.split(/\s+/))
    end
end

def part_two(input)
  card_map = input
    .lines
    .each_with_object({}) do |line, map|
      card_input, _, winning_numbers_input, _, my_numbers_input = line
        .strip
        .split(/(: | \| )/)

      card_number = card_input.split(" ").last.to_i

      map[card_number] = [winning_numbers_input.split(/\s+/), my_numbers_input.split(/\s+/)]
    end

  queue = card_map.keys
  count = 0

  while queue.any?
    count += 1
    card_number = queue.shift
    winning_numbers, my_numbers = card_map[card_number]

    copies_won = (winning_numbers & my_numbers).length

    copies_won
      .times
      .map do |i|
        card_number + i + 1
      end
      .select do |won_card_number|
        card_map[won_card_number]
      end
      .each do |won_card_number|
        queue << won_card_number
      end
  end

  count
end

def main
  puts("part one sample: #{part_one(File.read("inputs/four.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/four.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/four.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/four.txt"))}")
end

main if $0 == __FILE__
