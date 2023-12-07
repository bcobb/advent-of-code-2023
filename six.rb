def ways_to_win(max_time, min_distance)
  (0..max_time).count do |button_time|
    (max_time - button_time) * button_time > min_distance
  end
end

def part_two(input)
  time, distance = input
    .lines
    .map(&:strip)
    .map do |line|
      line.split(/\s+/).tap(&:shift).join.to_i
    end

  ways_to_win(time, distance)
end

def part_one(input)
  times_with_distances = input
    .lines
    .map(&:strip)
    .map do |line|
      line.split(/\s+/).tap(&:shift).map(&:to_i)
    end
    .then do |a, b|
      a.zip(b)
    end

  times_with_distances
    .map do |time, distance|
      ways_to_win(time, distance)
    end
    .reduce(&:*)
end

def main
  puts("part one sample: #{part_one(File.read("inputs/six.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/six.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/six.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/six.txt"))}")
end

main if $0 == __FILE__
