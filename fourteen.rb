def input_to_grid(input)
  input.lines.map { |line| line.strip.chars }
end

def direction_operations(direction)
  case direction
  when :north
    [:transpose]
  when :south
    [:transpose, :reverse]
  when :east
    [:reverse]
  when :west
    []
  end
end

def apply_operations(grid, operations)
  operations.reduce(grid) do |wip, operation|
    case operation
    when :transpose
      wip.transpose
    when :reverse
      wip.map(&:reverse)
    else
      wip
    end
  end
end

def rotate(grid, direction)
  apply_operations(grid, direction_operations(direction))
end

def unrotate(grid, direction)
  apply_operations(grid, direction_operations(direction).reverse)
end

def simulate(grid, direction)
  rotated = rotate(grid, direction)

  final_rolling_rock_positions = final_roll_positions(rotated)
  final_rolling_rock_lookup = final_rolling_rock_positions.each_with_index.each_with_object(Set.new) do |(positions, row), lookup|
    positions.each do |column|
      lookup << [row, column]
    end
  end

  simulated = rotated.map.with_index do |row_values, row|
    row_values.map.with_index do |column_value, column|
      if final_rolling_rock_lookup.include?([row, column])
        "O"
      elsif rotated[row][column] == "#"
        "#"
      else
        "."
      end
    end
  end

  unrotate(simulated, direction)
end

def simulate_cycle(grid)
  [:north, :west, :south, :east].reduce(grid) do |wip, direction|
    simulate(wip, direction)
  end
end

def signature(grid)
  rolling_rock_positions = grid
    .each_with_index
    .filter_map do |row_values, row|
      row_values.each_with_index.filter_map do |value, column|
        if value == "O"
          [row, column]
        end
      end
    end
    .flatten(1)
end

def time_to_repeat(grid)
  i = 0
  done = false
  initial_signature = signature(grid)
  signatures = {initial_signature => {i: 0, signature: initial_signature}}
  time_to_repeat = nil
  offset = nil
  convenient_lookup = nil

  while !done
    i += 1
    grid = simulate_cycle(grid)
    grid_signature = signature(grid)

    if signatures[grid_signature]
      time_to_repeat = i - signatures[grid_signature][:i]
      offset = signatures[grid_signature][:i]
      convenient_lookup = signatures.each_with_object({}) do |(signature, metadata), map|
        map[metadata[:i]] = metadata[:signature]
      end

      done = true
    else
      signatures[grid_signature] = {i: i, signature: grid_signature}
    end
  end

  [offset, time_to_repeat, convenient_lookup]
end

def part_two(input)
  grid = input_to_grid(input)
  offset, cycle_duration, lookup = time_to_repeat(grid)

  equivalent = (offset..(offset + cycle_duration)).find do |stripe|
    (1000000000 - stripe) % cycle_duration == 0
  end

  lookup[equivalent].sum { |row, col| grid.length - row }
end

def final_roll_positions(grid)
  grid.map do |row|
    positions = (0...row.length)

    square_rock_positions = positions.select do |index|
      row[index] == "#"
    end

    initial_rolling_rock_positions = positions.select do |index|
      row[index] == "O"
    end

    final_rolling_rock_positions = []

    offset = 0

    while final_rolling_rock_positions.length < initial_rolling_rock_positions.length
      square_rock_position = square_rock_positions.shift || row.length

      initial_rolling_rock_positions
        .select do |position|
          position < square_rock_position && position >= offset
        end
        .each_with_index do |roller, index|
          final_rolling_rock_positions << offset + index
        end

      offset = square_rock_position + 1
    end

    final_rolling_rock_positions
  end
end

def part_one(input)
  grid = simulate(input_to_grid(input), :north)

  signature(grid).sum { |row, column| grid.length - row }
end

def main
  puts("part one sample: #{part_one(File.read("inputs/fourteen.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/fourteen.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/fourteen.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/fourteen.txt"))}")
end

main if $0 == __FILE__
