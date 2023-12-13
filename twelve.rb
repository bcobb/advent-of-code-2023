require "debug"

def analyze(record, damages)
  if record.length < (damages.length - 1) + damages.sum
    return 0
  end

  if damages.empty?
    if record.to_set <= Set.new(["?", "."])
      return 1
    else
      return 0
    end
  end

  if record.first == "."
    return analyze(record[1..-1].to_a, damages)
  end

  possibilities = 0

  if record.first == "?"
    possibilities += analyze(record[1..-1].to_a, damages)
  end

  slice = record[0...damages.first]
  buffer_entry = record[damages.first]

  if slice.to_set <= Set.new(["?", "#"])
    if record.length > damages.first
      if buffer_entry != "#"
        possibilities += analyze(record[damages.first.succ..-1].to_a, damages[1..-1].to_a)
      end
    else
      possibilities += analyze(record[damages.first.succ..-1].to_a, damages[1..-1].to_a)
    end
  end

  possibilities
end

def part_one(input)
  parsed = input.lines.map do |line|
    conditions_input, damages_input = line.split(" ")
    conditions = conditions_input.chars
    damages = damages_input.split(",").map(&:to_i)

    [conditions, damages]
  end

  parsed.sum { |x| analyze(*x) }
end

def part_two(input)
  parsed = input.lines.map do |line|
    conditions_input, damages_input = line.split(" ")
    conditions = 5.times.map { conditions_input }.join("?").chars
    damages = 5.times.flat_map { damages_input.split(",").map(&:to_i) }

    [conditions, damages]
  end

  parsed.sum { |x| analyze(*x) }
end

def main
  puts("part one sample: #{part_one(File.read("inputs/twelve.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/twelve.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/twelve.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/twelve.txt"))}")
end

main if $0 == __FILE__
