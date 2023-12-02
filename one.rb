def part_one(input)
  input
    .lines
    .map do |line|
      digits = line.scan(/\d/)

      digits.first + digits.last
    end
    .sum(&:to_i)
end

def part_two(input)
  digits = %w[one two three four five six seven eight nine]

  digit_map = digits.each_with_index.to_h { |word, index| [word, (index + 1).to_s] }
  digit_pattern = /\d|#{digits.join("|")}/

  reverse_map = digit_map.transform_keys(&:reverse)
  reverse_pattern = /\d|#{reverse_map.keys.join("|")}/

  input
    .lines
    .map do |line|
      digits = line.scan(digit_pattern)
      reverse_digits = line.reverse.scan(reverse_pattern)

      (digit_map[digits.first] || digits.first) + (reverse_map[reverse_digits.first] || reverse_digits.first)
    end
    .sum(&:to_i)
end

def main
  real = File.read("inputs/one.txt")

  puts("part one sample: #{part_one(File.read("inputs/one.sample.txt"))}")
  puts("part one real: #{part_one(real)}")

  puts("part two sample: #{part_two(File.read("inputs/one.sample2.txt"))}")
  puts("part two real: #{part_two(real)}")
end

main if $0 == __FILE__
