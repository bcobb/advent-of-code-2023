def parse_input(input)
  initial_positions = input
    .lines
    .map(&:strip)
    .map do |line|
      line.split("~").map do |s|
        s.split(",").map(&:to_i)
      end
    end
    .sort_by do |(front, back)|
      front.last
    end

  blocks = initial_positions.each_with_index.each_with_object([]) do |((front, back), index), coll|
    fx, fy, fz = front
    bx, by, bz = back

    (fx..bx).each do |x|
      (fy..by).each do |y|
        (fz..bz).each do |z|
          coll << [index + 1, [x, y, z]]
        end
      end
    end
  end

  blocks.uniq!

  blocks
end

def simulate_fall(blocks)
  settled_numbers = blocks.select { |_, (_, _, z)| z == 1 }.map(&:first).uniq
  settled = blocks.select { |n, _| settled_numbers.include?(n) }
  falling_numbers = blocks.reject { |n, _| settled_numbers.include?(n) }.map(&:first).uniq

  supported_by = {}
  supporting = blocks.to_h { |number, _| [number, []] }

  while falling_numbers.any?
    falling_number = falling_numbers.shift
    falling_blocks = blocks.select { |n, _| n == falling_number }.map(&:last)
    supporting_blocks = []
    falling_distance = 0

    while supporting_blocks.empty?
      next_step = falling_blocks.map do |x, y, z|
        [x, y, z - (falling_distance + 1)]
      end

      possible_intersections = settled.select { |_, block| next_step.include?(block) }

      if possible_intersections.any?
        supporting_blocks = possible_intersections.map(&:first).uniq
      else
        if next_step.any? { |_, _, z| z == 0 }
          supporting_blocks = [0]
        else
          falling_distance += 1
        end
      end
    end

    supporting_blocks.each do |support|
      supported_by[falling_number] ||= []
      supported_by[falling_number] << support

      supporting[support] ||= []
      supporting[support] << falling_number
    end

    falling_blocks.each do |x, y, z|
      settled.unshift([falling_number, [x, y, z - falling_distance]])
    end
  end

  {settled: settled, supported_by: supported_by, supporting: supporting}
end

def part_one(input)
  blocks = parse_input(input)
  result = simulate_fall(blocks)

  numbers = blocks.map(&:first).uniq

  numbers
    .map do |number|
      {
        number: number,
        supporting_any: Array(result[:supporting][number]).any?,
        dependents_have_other_support: Array(result[:supporting][number]).all? { |dependent| Array(result[:supported_by][dependent]).length > 1 }
      }
    end
    .count do |summary|
      !summary[:supporting_any] || summary[:dependents_have_other_support]
    end
end

def disintigration_result(number, blocks_to_supports, blocks_to_dependents)
  if Array(blocks_to_dependents[number]).empty?
    []
  else
    disintigrated = [number]
    falling = []
    queue = blocks_to_dependents[number].dup

    while queue.any?
      dependent = queue.shift

      remaining_supports = blocks_to_supports[dependent] - disintigrated - falling

      if remaining_supports.empty?
        falling << dependent

        queue |= blocks_to_dependents[dependent]
      end
    end

    falling
  end
end

def disintigration_results(numbers, blocks_to_supports, blocks_to_dependents)
  numbers.reverse.each_with_object({}) do |number, map|
    result = disintigration_result(number, blocks_to_supports, blocks_to_dependents)

    map[number] = result
  end
end

def part_two(input)
  blocks = parse_input(input)
  result = simulate_fall(blocks)

  numbers = blocks.map(&:first).uniq.sort

  disintigration_results(numbers, result[:supported_by], result[:supporting]).sum { |_, falling| falling.length }
end

def main
  sample_input = File.read("inputs/twenty-two.sample.txt")
  input = File.read("inputs/twenty-two.txt")

  puts("part one sample: #{part_one(sample_input)}")
  puts("part one: #{part_one(input)}")

  puts("part two sample: #{part_two(sample_input)}")
  puts("part two: #{part_two(input)}")
end

main if $0 == __FILE__
