def compress_graph(graph)
  matrix = graph.each_with_object({}) do |(node, node_data), wip|
    wip[node] ||= {}
    node_data[:neighbors].each do |neighbor|
      wip[node][neighbor] = 1
    end
  end

  nodes = graph.keys

  nodes.each do |node|
    neighbors = matrix[node]

    if neighbors.length == 2
      left, right = neighbors.keys

      matrix[left].delete(node)
      matrix[right].delete(node)

      matrix[left][right] = [matrix[left][right] || 0, neighbors[left] + neighbors[right]].max
      matrix[right][left] = matrix[left][right]

      matrix.delete(node)
    end
  end

  matrix
end

def longest_path(matrix, origin, destination, visited_with_distance = {origin => 0})
  if origin == destination
    visited_with_distance.values.sum
  else
    longest = 0

    matrix[origin].each do |neighbor, weight|
      if visited_with_distance[neighbor].nil?
        length = longest_path(matrix, neighbor, destination, visited_with_distance.merge(neighbor => matrix[origin][neighbor]))

        if length > longest
          longest = length
        end
      end
    end

    longest
  end
end

def compute_paths(grid, treatment)
  graph = graph_from_grid(grid, treatment)

  path_distances = []

  destination = [grid.length - 1, grid.last.index(".")]
  origin = [0, grid.first.index(".")]

  queue = [[[], origin, "v"]]

  while queue.any?
    current = queue.shift
    path, coordinate, direction = current

    if coordinate == destination
      path_distances << path.length
      next
    end

    moves = valid_moves(graph, coordinate, direction)

    moves
      .reject do |new_coordinate, direction|
        path.include?(new_coordinate)
      end
      .each do |move|
        new_coordinate, direction = move
        new_path = path + [new_coordinate]

        queue << [new_path, new_coordinate, direction]
      end

    queue.sort_by! { |path, _| -path.length }
  end

  path_distances.max
end

def valid_moves(graph, coordinate, current_direction)
  tile = graph[coordinate][:tile]
  move_coordinates = graph[coordinate][:neighbors]

  initial_valid = move_coordinates.map do |move_coordinate|
    direction = case coordinate.zip(move_coordinate).map { |a, b| b - a }
    when [0, 1]
      ">"
    when [0, -1]
      "<"
    when [1, 0]
      "v"
    when [-1, 0]
      "^"
    else
      raise "wtf"
    end

    [move_coordinate, direction]
  end

  initial_valid.reject do |_, direction|
    case current_direction
    when "<"
      direction == ">"
    when ">"
      direction == "<"
    when "^"
      direction == "v"
    when "v"
      direction == "^"
    end
  end
end

def graph_from_grid(grid, treatment)
  grid.each_with_index.each_with_object({}) do |(row_values, row), graph|
    row_values.each_with_index do |value, column|
      coordinate = [row, column]
      tile = grid.dig(*coordinate)

      next if tile == "#"

      deltas = if (tile == "." || treatment == :normal)
        [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ]
      elsif tile == ">"
        [[0, 1]]
      elsif tile == "<"
        [[0, -1]]
      elsif tile == "^"
        [[-1, 0]]
      elsif tile == "v"
        [[1, 0]]
      else
        raise "unhandled tile #{tile} at #{coordinate}"
      end

      valid_neighbors = deltas.map { |delta| coordinate.zip(delta).map(&:sum) }.select do |neighbor_row, neighbor_column|
        neighbor_row.between?(0, grid.length - 1) &&
          neighbor_column.between?(0, grid.first.length - 1) &&
          grid.dig(neighbor_row, neighbor_column) != "#"
      end

      graph[[row, column]] = {tile: tile, neighbors: valid_neighbors}
    end
  end
end

def grid_from_input(input)
  input.lines.map { |line| line.strip.chars }
end

def part_one(input)
  grid = grid_from_input(input)
  compute_paths(grid, :steep)
end

def part_two(input)
  grid = grid_from_input(input)

  destination = [grid.length - 1, grid.last.index(".")]
  origin = [0, grid.first.index(".")]

  graph = graph_from_grid(grid, :normal)
  compressed_adjacency_matrix = compress_graph(graph)

  longest_path(compressed_adjacency_matrix, origin, destination)
end

def main
  sample_input = File.read("inputs/twenty-three.sample.txt")
  input = File.read("inputs/twenty-three.txt")

  # puts("part one sample: #{part_one(sample_input)}")
  # puts("part one: #{part_one(input)}")

  puts("part two sample: #{part_two(sample_input)}")
  puts("part two: #{part_two(input)}")
end

main if $0 == __FILE__
