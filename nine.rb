def extrapolate(history)
  steps = [history.dup]

  while !steps.first.all?(&:zero?)
    steps.unshift(steps.first.each_cons(2).map { |a, b| b - a })
  end

  steps
    .each
    .with_index do |step_history, index|
      if index == 0
        step_history << step_history.last
        step_history.unshift(step_history.first)
      else
        previous_last_step_size = steps[index - 1].last
        previous_first_step_size = steps[index - 1].first

        step_history << step_history.last + previous_last_step_size
        step_history.unshift(step_history.first - previous_first_step_size)
      end
    end
    .last
end

def part_one(input)
  histories = input.lines.map(&:strip).map do |line|
    line.split(/\s+/).map(&:to_i)
  end

  histories.sum { |history| extrapolate(history).last }
end

def part_two(input)
  histories = input.lines.map(&:strip).map do |line|
    line.split(/\s+/).map(&:to_i)
  end

  histories.sum { |history| extrapolate(history).first }
end

def main
  puts("part one sample: #{part_one(File.read("inputs/nine.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/nine.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/nine.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/nine.txt"))}")
end

main if $0 == __FILE__
