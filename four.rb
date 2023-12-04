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

def main
  puts("part one sample: #{part_one(File.read("inputs/four.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/four.txt"))}")
end

main if $0 == __FILE__
