def parse_line(line)
  direction, length, color_input = line.strip.split(/\s+/)
  color = color_input.scan(/#([a-f0-9]+)/).first.first
  color_direction = color[5].to_i
  color_length = color[0..4].to_i(16)

  {
    direction: direction,
    length: length.to_i,
    color_direction: color_direction,
    color_length: color_length
  }
end

def find_vertexes(instructions, length_key = :length, direction_key = :direction)
  vertexes = [[0, 0]]

  instructions.each_with_object(vertexes) do |instruction, coll|
    x, y = coll.last
    length, direction = instruction.values_at(length_key, direction_key)

    case direction
    when "R", 0
      coll << [x + length, y]
    when "L", 2
      coll << [x - length, y]
    when "U", 3
      coll << [x, y + length]
    when "D", 1
      coll << [x, y - length]
    else
      raise "Got direction #{direction}"
    end
  end
end

def input_to_instructions(input)
  input.lines.map { |line| parse_line(line) }
end

def perimeter(vertexes)
  vertexes.each_cons(2).sum { |p_a, p_b| p_a.zip(p_b).sum { |a, b| (a - b).abs } }
end

def shoelace_area(vertexes)
  base = (vertexes + [vertexes.first]).each_cons(2).sum do |p_a, p_b|
    row_a, col_a = p_a
    row_b, col_b = p_b

    (row_a * col_b) - (col_a * row_b)
  end

  (base / 2).abs
end

def part_one(input)
  vertexes = find_vertexes(input_to_instructions(input))

  shoelace_area(vertexes) + (perimeter(vertexes) / 2) + 1
end

def part_two(input)
  vertexes = find_vertexes(input_to_instructions(input), :color_length, :color_direction)

  shoelace_area(vertexes) + (perimeter(vertexes) / 2) + 1
end

def main
  puts("part one sample: #{part_one(File.read("inputs/eighteen.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/eighteen.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/eighteen.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/eighteen.txt"))}")
end

main if $0 == __FILE__
