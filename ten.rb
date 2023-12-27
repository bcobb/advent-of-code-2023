OPPOSITE_DIRECTIONS = {
  up: :down,
  down: :up,
  left: :right,
  right: :left
}

TILE_ENTER_DIRECTIONS = {
  "|" => [:down, :up],
  "-" => [:left, :right],
  "L" => [:down, :left],
  "J" => [:down, :right],
  "7" => [:up, :right],
  "F" => [:up, :left]
}

TILE_EXIT_DIRECTIONS = TILE_ENTER_DIRECTIONS.transform_values { |directions| directions.map(&OPPOSITE_DIRECTIONS) }

DELTA_TO_DIRECTION = {
  [1, 0] => :down,
  [-1, 0] => :up,
  [0, 1] => :right,
  [0, -1] => :left
}

DIRECTION_TO_DELTA = DELTA_TO_DIRECTION.invert

def starting_location(grid)
  grid
    .each_with_index
    .filter_map do |row_values, row|
      row_values
        .each_with_index
        .filter_map do |value, column|
          if value == "S"
            [row, column]
          end
        end
        .first
    end
    .first
end

def possible_moves(grid, loc)
  pipe = grid.dig(*loc)
  exit_directions = Array(TILE_EXIT_DIRECTIONS[pipe])

  DELTA_TO_DIRECTION
    .select do |delta, direction|
      exit_directions.empty? || exit_directions.include?(direction)
    end
    .filter_map do |delta, direction|
      new_loc = loc.zip(delta).map(&:sum)
      new_pipe = grid.dig(*new_loc)
      entry_directions = Array(TILE_ENTER_DIRECTIONS[new_pipe])

      if entry_directions.include?(direction)
        [new_loc, delta]
      end
    end
end

def determine_starting_pipe(grid, starting_loc)
  exit_directions = possible_moves(grid, starting_loc).map(&:last).map(&DELTA_TO_DIRECTION).map(&OPPOSITE_DIRECTIONS)

  TILE_ENTER_DIRECTIONS
    .find do |tile, tile_enter_directions|
      (tile_enter_directions & exit_directions).length == 2
    end
    .first
end

def grid_with_known_starting_pipe(grid, starting_loc)
  starting_row, starting_column = starting_loc
  starting_pipe = determine_starting_pipe(grid, starting_loc)

  grid.map.with_index do |column_values, row|
    column_values.map.with_index do |value, column|
      if row == starting_row && column == starting_column
        starting_pipe
      else
        value
      end
    end
  end
end

def grid_from_input(input)
  input.lines.map(&:strip).map do |line|
    line.chars
  end
end

def compute_paths(graph, starting_loc)
  distances_from_start = {
    starting_loc => 0
  }

  graph.each do |loc, _|
    distances_from_start[loc] ||= Float::INFINITY
  end

  queue = graph.keys.sort_by(&distances_from_start)

  while queue.any?
    loc = queue.shift

    graph[loc].each do |neighbor|
      loc_distance_from_start = distances_from_start[loc] + 1

      if loc_distance_from_start < distances_from_start[neighbor]
        distances_from_start[neighbor] = loc_distance_from_start
      end
    end

    queue.sort_by!(&distances_from_start)
  end

  {distances: distances_from_start}
end

def build_graph(grid, starting_loc)
  graph = {}
  queue = [starting_loc]

  while queue.any?
    current_loc = queue.shift

    if graph[current_loc].nil?
      adjacent_locs = possible_moves(grid, current_loc).map(&:first)

      graph[current_loc] = adjacent_locs.map do |loc|
        loc
      end

      queue += adjacent_locs
    end
  end

  graph
end

def inflate(grid, graph)
  empty_square = 3.times.map { 3.times.map { "." } }

  grid
    .map
    .with_index do |row_values, row|
      row_values.map.with_index do |value, column|
        if graph[[row, column]]
          case grid.dig(row, column)
          when "|"
            [
              [".", "|", "."],
              [".", "|", "."],
              [".", "|", "."]
            ]
          when "-"
            [
              [".", ".", "."],
              ["-", "-", "-"],
              [".", ".", "."]
            ]
          when "F"
            [
              [".", ".", "."],
              [".", "F", "-"],
              [".", "|", "."]
            ]
          when "J"
            [
              [".", "|", "."],
              ["-", "J", "."],
              [".", ".", "."]
            ]
          when "L"
            [
              [".", "|", "."],
              [".", "L", "-"],
              [".", ".", "."]
            ]
          when "7"
            [
              [".", ".", "."],
              ["-", "7", "."],
              [".", "|", "."]
            ]
          else
            raise "invalid tile"
          end
        else
          empty_square
        end
      end
    end
    .flat_map do |blocks|
      blocks.each_with_object([]) do |block, wip|
        block.each.with_index do |row_values, row|
          if wip[row]
            wip[row] += row_values
          else
            wip << row_values
          end
        end
      end
    end
end

def inflated_blanks(inflated_grid)
  rows = (0...inflated_grid.length)
  columns = (0...inflated_grid.first.length)

  rows
    .each_slice(3)
    .flat_map do |row_slice|
      columns.each_slice(3).map do |column_slice|
        row_slice.map do |row|
          column_slice.map do |column|
            inflated_grid.dig(row, column)
          end
        end
      end
    end
    .select do |tiles|
      tiles.flatten.length == 9 && tiles.flatten.all?(".")
    end
end

def determine_paint(normalized_grid)
  vertical_perimeter = (0...normalized_grid.length).flat_map do |row|
    [0, normalized_grid.first.length - 1].filter_map do |column|
      [row, column] if normalized_grid.dig(row, column) == "."
    end
  end

  horizontal_perimeter = (0...normalized_grid.first.length).flat_map do |column|
    [0, normalized_grid.length - 1].filter_map do |row|
      [row, column] if normalized_grid.dig(row, column) == "."
    end
  end

  perimeter = vertical_perimeter + horizontal_perimeter

  paint = perimeter.to_h { |c| [c, :ether] }

  all_coordinates = (0...normalized_grid.length).flat_map do |row|
    (0...normalized_grid.first.length).map do |column|
      [row, column]
    end
  end

  all_coordinates.each do |coordinate|
    if normalized_grid.dig(*coordinate) != "."
      paint[coordinate] = :pipe
    end
  end

  queue = perimeter

  while queue.any?
    current = queue.shift
    row, column = current

    neighbors = DELTA_TO_DIRECTION
      .keys
      .map do |delta|
        current.zip(delta).map(&:sum)
      end
      .select do |neighbor|
        on_grid?(normalized_grid, neighbor) && paint[neighbor].nil?
      end
      .each do |unpainted_neighbor|
        paint[unpainted_neighbor] = :ether
        queue << unpainted_neighbor
      end
  end

  paint
end

def on_grid?(grid, coordinate)
  row, column = coordinate
  row >= 0 && column >= 0 && row < grid.length && column < grid.first.length
end

def apply_paint(normalized_grid, data)
  normalized_grid.map.with_index do |row_values, row|
    row_values.map.with_index do |value, column|
      case data[[row, column]]
      when :ether
        "O"
      when :maybe_interior
        "I"
      else
        value
      end
    end
  end
end

def part_two(input)
  input_grid = grid_from_input(input)
  starting_loc = starting_location(input_grid)

  actual_grid = grid_with_known_starting_pipe(input_grid, starting_loc)

  graph = build_graph(actual_grid, starting_loc)

  inflated = inflate(actual_grid, graph)
  paint = determine_paint(inflated)
  inflated_and_painted = apply_paint(inflated, paint)
  inflated_blanks(inflated_and_painted).length
end

def part_one(input)
  input_grid = grid_from_input(input)
  starting_loc = starting_location(input_grid)

  actual_grid = grid_with_known_starting_pipe(input_grid, starting_loc)

  graph = build_graph(actual_grid, starting_loc)

  paths = compute_paths(graph, starting_loc)

  paths[:distances].values.max
end

def main
  puts("part one samples")
  %w[1 2].each do |n|
    puts("  #{n} => #{part_one(File.read("inputs/ten.sample#{n}.txt"))}")
  end

  puts("part one: #{part_one(File.read("inputs/ten.txt"))}")

  puts("part two samples")

  %w[1 2 3 4 5 6].each do |n|
    puts("  #{n} => #{part_two(File.read("inputs/ten.sample#{n}.txt"))}")
  end

  puts("part two: #{part_two(File.read("inputs/ten.txt"))}")
end

main if $0 == __FILE__
