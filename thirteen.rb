def reflection_size(grid, smudged = false)
  differences = smudged ? 1 : 0

  (1...grid.length)
    .select do |row|
      size = [row, grid.length - row].min

      before_range = (row - size)...row
      after_range = row...(row + size)

      before_range.to_a.zip(after_range.to_a.reverse).sum do |before, after|
        grid[before].zip(grid[after]).count { |before_value, after_value| before_value != after_value }
      end == differences
    end
    .sum
end

def part_one(input)
  grids = input
    .split(/\n\n/)
    .map do |grid_inputs|
      grid_inputs.lines.map(&:strip).map(&:chars)
    end

  grids.sum do |grid|
    100 * reflection_size(grid) + reflection_size(grid.transpose)
  end
end

def part_two(input)
  grids = input
    .split(/\n\n/)
    .map do |grid_inputs|
      grid_inputs.lines.map(&:strip).map(&:chars)
    end

  grids.sum do |grid|
    100 * reflection_size(grid, true) + reflection_size(grid.transpose, true)
  end
end

def main
  puts("part one sample: #{part_one(File.read("inputs/thirteen.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/thirteen.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/thirteen.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/thirteen.txt"))}")
end

main if $0 == __FILE__
