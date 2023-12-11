def rows_to_expand(grid)
  grid
    .each_with_index
    .select do |row, index|
      row.all?(".")
    end
    .map(&:last)
end

def columns_to_expand(grid)
  grid.length.times.select do |index|
    grid.all? { |row| row[index] == "." }
  end
end

def expand(grid)
  empty_rows = rows_to_expand(grid)
  empty_columns = columns_to_expand(grid)

  with_extra_columns = grid.map do |row|
    row.each_with_index.flat_map do |value, index|
      if empty_columns.include?(index)
        [value, value]
      else
        value
      end
    end
  end

  with_extra_columns.each_with_index.each_with_object([]) do |(row, index), new_grid|
    if empty_rows.include?(index)
      2.times { new_grid << row }
    else
      new_grid << row
    end
  end
end

def galaxy_positions(grid)
  grid
    .each_with_index
    .filter_map do |row_values, row|
      positions = row_values.each_with_index.filter_map do |value, column|
        if value == "#"
          [row, column]
        end
      end

      positions.any? ? positions : nil
    end
    .flatten(1)
end

def manhattan_distance(a, b)
  a.zip(b).sum { |c1, c2| (c1 - c2).abs }
end

def manhattan_rows(a, b)
  a_row, _ = a
  b_row, _ = b

  if a_row < b_row
    (a_row..b_row).to_a
  else
    (b_row..a_row).to_a
  end
end

def manhattan_columns(a, b)
  _, a_column = a
  _, b_column = b

  if a_column < b_column
    (a_column..b_column).to_a
  else
    (b_column..a_column).to_a
  end
end

def grid_from_input(input)
  input.lines.map(&:strip).map(&:chars)
end

def part_one(input)
  grid = grid_from_input(input)
  expanded_grid = expand(grid)
  galaxy_positions = galaxy_positions(expanded_grid)

  galaxy_positions.combination(2).sum { |combo| manhattan_distance(*combo) }
end

def part_two(input, expansion_factor:)
  grid = grid_from_input(input)

  expanded_rows = rows_to_expand(grid)
  expanded_columns = columns_to_expand(grid)

  galaxy_positions = galaxy_positions(grid)

  galaxy_positions.combination(2).sum do |combo|
    traversed_rows = manhattan_rows(*combo)
    traversed_columns = manhattan_columns(*combo)

    warp_rows = expanded_rows & traversed_rows
    warp_columns = expanded_columns & traversed_columns

    manhattan_distance(*combo) + ((expansion_factor - 1) * warp_rows.length) + ((expansion_factor - 1) * warp_columns.length)
  end
end

def main
  puts("part one sample: #{part_one(File.read("inputs/eleven.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/eleven.txt"))}")

  puts("part two sample check: #{part_two(File.read("inputs/eleven.sample.txt"), expansion_factor: 2)}")
  puts("part two check: #{part_two(File.read("inputs/eleven.txt"), expansion_factor: 2)}")

  puts("part two sample 1: #{part_two(File.read("inputs/eleven.sample.txt"), expansion_factor: 10)}")
  puts("part two sample 2: #{part_two(File.read("inputs/eleven.sample.txt"), expansion_factor: 100)}")

  puts("part two: #{part_two(File.read("inputs/eleven.txt"), expansion_factor: 1000000)}")
end

main if $0 == __FILE__
