def compute_paths(grid, move_calculator, min_final_steps)
  graph = graph_from_grid(grid)
  visited = Set.new
  destination = graph.keys.max
  origin = [0, 0]

  queue = [[0, origin, ">", 0], [0, origin, "v", 0]]

  while queue.any?
    current = queue.shift
    heat_loss, coordinate, direction, current_steps = current

    if coordinate == destination && current_steps >= min_final_steps
      break heat_loss
    end

    moves = move_calculator.call(graph, coordinate, direction, current_steps)

    moves
      .reject do |move|
        visited.include?(move)
      end
      .each do |move|
        next_coordinate, direction, next_steps = move
        new_heat_loss = grid.dig(*next_coordinate) + heat_loss

        queue << [new_heat_loss, next_coordinate, direction, next_steps]
        visited << move
      end

    queue.sort_by!(&:first)
  end

  heat_loss
end

def valid_moves(graph, coordinate, direction, steps)
  result = []

  if steps < 2
    case direction
    when ">"
      result << [[0, 1].zip(coordinate).map(&:sum), direction, steps + 1]
    when "<"
      result << [[0, -1].zip(coordinate).map(&:sum), direction, steps + 1]
    when "^"
      result << [[-1, 0].zip(coordinate).map(&:sum), direction, steps + 1]
    when "v"
      result << [[1, 0].zip(coordinate).map(&:sum), direction, steps + 1]
    end
  end

  case direction
  when ">", "<"
    result << [[1, 0].zip(coordinate).map(&:sum), "v", 0]
    result << [[-1, 0].zip(coordinate).map(&:sum), "^", 0]
  when "^", "v"
    result << [[0, 1].zip(coordinate).map(&:sum), ">", 0]
    result << [[0, -1].zip(coordinate).map(&:sum), "<", 0]
  end

  result.select do |new_coordinate, _|
    graph[new_coordinate]
  end
end

def valid_ultra_moves(graph, coordinate, direction, steps)
  result = []

  keep_going = case direction
  when ">"
    [[0, 1].zip(coordinate).map(&:sum), direction, steps + 1]
  when "<"
    [[0, -1].zip(coordinate).map(&:sum), direction, steps + 1]
  when "^"
    [[-1, 0].zip(coordinate).map(&:sum), direction, steps + 1]
  when "v"
    [[1, 0].zip(coordinate).map(&:sum), direction, steps + 1]
  end

  possible_turns = case direction
  when ">", "<"
    [
      [[1, 0].zip(coordinate).map(&:sum), "v", 0],
      [[-1, 0].zip(coordinate).map(&:sum), "^", 0]
    ]
  when "^", "v"
    [
      [[0, 1].zip(coordinate).map(&:sum), ">", 0],
      [[0, -1].zip(coordinate).map(&:sum), "<", 0]
    ]
  end

  if steps < 3
    result << keep_going
  else
    if steps < 9
      result << keep_going
      result += possible_turns
    else
      result += possible_turns
    end
  end

  result.select do |new_coordinate, _|
    graph[new_coordinate]
  end
end

def graph_from_grid(grid)
  grid.each_with_index.each_with_object({}) do |(row_values, row), graph|
    row_values.each_with_index do |value, column|
      graph[[row, column]] = [
        [row - 1, column],
        [row + 1, column],
        [row, column - 1],
        [row, column + 1]
      ].select do |neighbor_row, neighbor_column|
        neighbor_row.between?(0, grid.length - 1) && neighbor_column.between?(0, grid.first.length - 1)
      end
    end
  end
end

def grid_from_input(grid)
  grid.lines.map { |line| line.strip.chars.map(&:to_i) }
end

def part_one(input)
  grid = grid_from_input(input)
  compute_paths(grid, method(:valid_moves), 0)
end

def part_two(input)
  grid = grid_from_input(input)
  compute_paths(grid, method(:valid_ultra_moves), 3)
end

def main
  puts("part one sample #{part_one(File.read("inputs/seventeen.sample.txt"))}")
  puts("part one #{part_one(File.read("inputs/seventeen.txt"))}")

  puts("part two sample #{part_two(File.read("inputs/seventeen.sample.txt"))}")
  puts("part two sample 2 #{part_two(File.read("inputs/seventeen.sample2.txt"))}")
  puts("part two #{part_two(File.read("inputs/seventeen.txt"))}")
end

main if $0 == __FILE__
