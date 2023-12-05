class Almanac
  def initialize(label, mappers)
    @label = label
    @mappers = mappers
  end

  def map(number)
    maybe_mapped_number = @mappers
      .filter_map do |mapper|
        mapper.map(number)
      end
      .first

    maybe_mapped_number || number
  end
end

class Mapper
  def initialize(source_range_start:, destination_range_start:, range_length:)
    @source_range_start = source_range_start
    @destination_range_start = destination_range_start
    @range_length = range_length
  end

  def map(number)
    if number >= @source_range_start && number < @source_range_start + @range_length
      offset = number - @source_range_start

      @destination_range_start + offset
    end
  end
end

def parse_input(input)
  seeds_input, *mapping_inputs = input.split(/\n{2,}/)
  seeds = seeds_input.split(": ").last.split(" ").map(&:to_i)
  almanacs = mapping_inputs.map do |mapping_input|
    label, *map_input = mapping_input.lines.map(&:strip)
    mappers = map_input.map do |line|
      destination_range_start, source_range_start, range_length = line.split(" ").map(&:to_i)

      Mapper.new(destination_range_start: destination_range_start, source_range_start: source_range_start, range_length: range_length)
    end

    Almanac.new(
      label,
      mappers
    )
  end

  [seeds, almanacs]
end

def part_one(input)
  seeds, almanacs = parse_input(input)

  seeds
    .map do |seed|
      position = almanacs.reduce(seed) do |position, almanac|
        almanac.map(position)
      end

      position
    end
    .min
end

def main
  puts("part one sample: #{part_one(File.read("inputs/five.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/five.txt"))}")
end

main if $0 == __FILE__
