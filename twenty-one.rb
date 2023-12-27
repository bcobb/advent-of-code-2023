DELTAS = [
  [0, 1],
  [1, 0],
  [-1, 0],
  [0, -1]
]

def input_to_grid(input)
  starting_pos = nil

  grid = input.lines.each_with_object([]) do |line, grid|
    row = grid.length
    column_values = line.strip.chars

    grid << column_values

    maybe_starting_column = column_values.index("S")

    if maybe_starting_column
      starting_pos = [row, maybe_starting_column]
    end
  end

  [grid, starting_pos]
end

def visitable_neighbors(grid, pos)
  DELTAS
    .map do |delta|
      delta.zip(pos).map(&:sum)
    end
    .select do |new_pos|
      new_value = grid.dig(*new_pos)

      new_value && new_value != "#"
    end
end

def explore_finite(grid, starting_pos, steps)
  occupied_coordinates = Set.new([starting_pos])

  puts("exploring #{steps} steps")

  steps.times do
    occupied_coordinates = occupied_coordinates.reduce(Set.new) do |wip, coordinate|
      wip += visitable_neighbors(grid, coordinate)
    end
  end

  occupied_coordinates
end

class InfiniteGridStepper
  def initialize(grid)
    @grid = grid
    @memory = {}
  end

  attr_reader :grid

  def moves_from(coordinate)
    return @memory[coordinate] if @memory[coordinate]

    DELTAS
      .map do |delta|
        coordinate.zip(delta).map(&:sum)
      end
      .map do |maybe_next_coordinate|
        if valid_coordinate?(maybe_next_coordinate)
          [[0, 0], maybe_next_coordinate]
        else
          grid_position_delta = [0, 0]
          actual_next_coordinate = maybe_next_coordinate.dup
          maybe_next_row, maybe_next_column = maybe_next_coordinate

          if maybe_next_row < 0
            grid_position_delta[0] = -1
            actual_next_coordinate[0] = grid.length + maybe_next_row
          elsif maybe_next_row >= grid.length
            grid_position_delta[0] = 1
            actual_next_coordinate[0] = maybe_next_row - grid.length
          end

          if maybe_next_column < 0
            grid_position_delta[1] = -1
            actual_next_coordinate[1] = grid.first.length + maybe_next_column
          elsif maybe_next_column >= grid.first.length
            grid_position_delta[1] = 1
            actual_next_coordinate[1] = maybe_next_column - grid.first.length
          end

          [grid_position_delta, actual_next_coordinate]
        end
      end
      .select do |_, next_coordinate|
        grid.dig(*next_coordinate) != "#"
      end
      .tap do |result|
        @memory[coordinate] = result
      end
  end

  def valid_coordinate?(coordinate)
    row, col = coordinate

    row >= 0 && col >= 0 && row < grid.length && col < grid.first.length
  end
end

def illustrate(possibilities, grid)

  sub_grids = possibilities.values.reduce(&:+)

  inversion = possibilities.each_with_object({}) do |(coordinate, grid_positions), wip|
    grid_positions.each do |grid_position|
      wip[grid_position] ||= Set.new
      wip[grid_position] << coordinate
    end
  end

  illustrated_sub_grids = sub_grids.map do |sub_grid|
    occupied = inversion.fetch(sub_grid)

    grid.map.with_index do |row_values, row|
      row_values.map.with_index do |value, column|
        if occupied.include?([row, column])
          "0"
        else
          value
        end
      end
    end
  end

  lookup_illustrated_sub_grids = sub_grids.zip(illustrated_sub_grids).to_h

  translation = 0
  min_grid_position = sub_grids.to_a.flatten.min
  max_grid_position = sub_grids.to_a.flatten.max

  if min_grid_position < 0
    translation = min_grid_position.abs
  end

  larger_grid_size = (max_grid_position - min_grid_position) + 1

  wip_grids = larger_grid_size.times.map do |grid_position_row|
    larger_grid_size.times.map do |grid_position_column|
      sub_grid_lookup_key = [grid_position_row - translation, grid_position_column - translation]

      if lookup_illustrated_sub_grids[sub_grid_lookup_key]
        lookup_illustrated_sub_grids[sub_grid_lookup_key]
      else
        grid
      end
    end
  end

  final_grid = []

  wip_grids.each.with_index do |row_of_sub_grids, row_offset|
    row_of_sub_grids.each do |sub_grid|
      sub_grid.each.with_index do |row_values, row|
        actual_row = row + (sub_grid.length * row_offset)

        if final_grid[actual_row]
          final_grid[actual_row] += row_values
        else
          final_grid << row_values
        end
      end
    end
  end
end

def explore_infinite(grid, starting_pos, steps)
  stepper = InfiniteGridStepper.new(grid)
  possibilities = {
    starting_pos => Set.new([[0, 0]])
  }

  steps.times do |i|
    possibilities = possibilities.each_with_object({}) do |(coordinate, grid_positions), wip|
      stepper.moves_from(coordinate).each do |grid_position_delta, next_coordinate|
        new_grid_positions = grid_positions.reduce(Set.new) { |s, grid_position| s << [grid_position[0] + grid_position_delta[0], grid_position[1] + grid_position_delta[1]] }

        wip[next_coordinate] ||= Set.new
        wip[next_coordinate] += new_grid_positions
      end
    end
  end

  possibilities.values.sum(&:length)
end

# thanks, reddit
def lagrange(y0, y1, y2)
  [
    (y0 / 2.0) - y1 + (y2 / 2.0),
    (-3.0 * (y0 / 2.0)) + (2.0 * y1) - (y2 / 2.0),
    y0
  ]
end

def part_two(input)
  grid, starting_pos = input_to_grid(input)

  y0, y1, y2 = (0..2).map { |offset_factor| explore_infinite(grid, starting_pos, 65 + (offset_factor * 131)) }
  x0, x1, x2 = lagrange(y0, y1, y2)
  target = (26501365 - 65) / 131

  (x0 * (target ** 2)) + (x1 * target) + x2
end

def part_one(input, steps)
  grid, starting_pos = input_to_grid(input)
  explore_finite(grid, starting_pos, steps).length
end

def main
  sample_input = File.read("inputs/twenty-one.sample.txt")
  input = File.read("inputs/twenty-one.txt")
  puts("part one sample #{part_one(sample_input, 6)}")
  puts("part one #{part_one(input, 64)}")

  puts("part two #{part_two(input)}")
end

main if $0 == __FILE__
