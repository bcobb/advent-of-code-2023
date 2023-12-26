def graph_from_input(input)
  input.lines.map(&:strip).each_with_object({}) do |line, map|
    component, connections_input = line.split(": ")
    connections = connections_input.split(" ")

    map[component] ||= []
    map[component] += connections

    connections.each do |connection|
      map[connection] ||= []
      map[connection] << component
    end
  end
end

def navigate(graph, origin, destination)
  distances_from_start = {
    origin => 0
  }

  previous_nodes = {}

  graph.each do |loc, _|
    distances_from_start[loc] ||= Float::INFINITY
  end

  queue = graph.keys.sort_by { |node| distances_from_start[node] }

  while queue.any?
    current = queue.shift

    graph[current].each do |neighbor|
      possible_distance_from_start = distances_from_start[current] + 1

      if possible_distance_from_start < distances_from_start[neighbor]
        distances_from_start[neighbor] = possible_distance_from_start
        previous_nodes[neighbor] = current
      end
    end

    queue.sort_by! { |node| distances_from_start[node] }
  end

  current = destination
  path = [current]

  while previous_nodes[current]
    path.unshift(previous_nodes[current])
    current = previous_nodes[current]
  end

  {
    path: path,
    distances: distances_from_start
  }
end

def graph_without_edges!(graph, edges)
  edges.reduce(graph) do |wip, (node_a, node_b)|
    graph[node_a].reject! { |neighbor| neighbor == node_b }
    graph[node_b].reject! { |neighbor| neighbor == node_a }
  end
end

def part_one(input)
  graph = graph_from_input(input)
  size = graph.keys.length

  origin = graph.keys.first
  arbitrary_destination = (graph.keys - [origin]).first

  stat = navigate(graph, origin, arbitrary_destination)

  farthest = stat[:distances].sort_by { |node, distance| -distance }.first(3)
  farthest.each do |far_destination, _|
    far_stat = navigate(graph, origin, far_destination)
    graph_without_edges!(graph, far_stat[:path].each_cons(2).to_a)
  end

  again = navigate(graph, origin, arbitrary_destination)

  again[:distances].partition { |_, distance| distance == Float::INFINITY }.map(&:count).reduce(&:*)
end

def main
  sample_input = File.read("inputs/twenty-five.sample.txt")
  input = File.read("inputs/twenty-five.txt")

  puts("part one sample: #{part_one(sample_input)}")
  puts("part one: #{part_one(input)}")
end

main if $0 == __FILE__
