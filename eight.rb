def build_graph(input)
  _, rest = input.split(/\n\n/)
  rest.lines.map(&:strip).each_with_object({}) do |line, graph|
    node, connections_input = line.split(" = ")
    left, right = connections_input.scan(/[0-9A-Z]+/)

    graph[node] = {"L" => left, "R" => right}
  end
end

def read_instructions(input)
  input.split(/\n\n/).first.chars
end

def part_one(input)
  instructions = read_instructions(input)
  graph = build_graph(input)
  location = "AAA"
  steps = 0

  while location != "ZZZ"
    instruction = instructions[steps % instructions.length]

    location = graph[location][instruction]

    steps += 1
  end

  steps
end

def check_destination!(hits)
  hits.length > 1 && hits.map(&:last).uniq.length == 1
end

def check_length!(hits)
  hits.length > 1 && hits.map(&:first).uniq.length == 1
end

def part_two(input)
  instructions = read_instructions(input)
  graph = build_graph(input)

  origins = graph.keys.grep(/A\z/)

  hit_sequences = origins.map do |current|
    steps = 0
    hits = []

    while hits.length < 2
      instruction = instructions[steps % instructions.length]

      new_location = graph[current][instruction]

      if new_location.end_with?("Z")
        hits << [steps + 1, new_location]
      end

      current = new_location
      steps += 1
    end

    hits
  end

  hit_sequences.each { |hits| check_destination!(hits) }
  hit_sequences.each { |hits| check_length!(hits) }

  hit_sequences.map(&:first).map(&:first).reduce(&:lcm)
end

def main
  puts("part one samples")
  %w[1 2].each do |n|
    puts("  #{n} => #{part_one(File.read("inputs/eight.sample#{n}.txt"))}")
  end

  puts("part one: #{part_one(File.read("inputs/eight.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/eight.sample3.txt"))}")
  puts("part two: #{part_two(File.read("inputs/eight.txt"))}")
end

main if $0 == __FILE__
