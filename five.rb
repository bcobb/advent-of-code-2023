class Map
  def initialize(label, mappings)
    @label = label
    @mappings = mappings
  end

  attr_reader :mappings
end

class Mapping
  include Comparable

  def initialize(source_range, destination_range)
    @source_range = source_range
    @destination_range = destination_range
  end

  protected attr_reader(:source_range)

  def mappable_range(seed_range)
    @source_range & seed_range
  end

  def map_range(seed_range)
    mappable_range = @source_range & seed_range

    if mappable_range
      mappable_range.map(&method(:apply))
    end
  end

  def <=>(other)
    source_range <=> other.source_range
  end

  def apply(seed)
    if (seed >= @source_range.start && seed <= @source_range.stop)
      @destination_range.start + (seed - @source_range.start)
    end
  end

  def before
    if @source_range.start > 0
      range = SeedRange.new(0, @source_range.start - 1)

      Mapping.new(range, range)
    end
  end

  def after
    range = SeedRange.new(@source_range.stop + 1, Float::INFINITY)

    Mapping.new(range, range)
  end
end

class SeedRange
  include Comparable

  def initialize(start, stop)
    raise ArgumentError.new("start (#{start}) cannot exceed stop (#{stop})") if start > stop

    @start = start
    @stop = stop
  end

  attr_reader :start
  attr_reader :stop

  def <=>(other)
    start_result = start <=> other.start

    if start_result == 0
      stop <=> other.stop
    else
      start_result
    end
  end

  def &(other)
    # this is either totally before or totally after the other range
    if stop < other.start || start > other.stop
      nil
    else
      if start < other.start
        # starts before other, ends in the middle of or after other
        # intersection is other's start until the smallest of the two possible stopping points
        SeedRange.new(other.start, [stop, other.stop].min)
      else
        # starts inside other, ends in the middle of or after other
        # intersection is this starting point until the smallest of the two possible stopping points
        SeedRange.new(start, [stop, other.stop].min)
      end
    end
  end

  def map(&fn)
    SeedRange.new(fn.call(start), fn.call(stop))
  end
end

def maps_from_input(input)
  _, *map_inputs = input.split(/\n{2,}/)

  map_inputs.map do |map_input|
    label, *mapping_inputs = map_input.lines.map(&:strip)

    mappings = mapping_inputs
      .map do |mapping_input|
        destination_range_start, source_range_start, length = mapping_input.split(" ").map(&:to_i)

        Mapping.new(
          SeedRange.new(source_range_start, source_range_start + length - 1),
          SeedRange.new(destination_range_start, destination_range_start + length - 1)
        )
      end
      .sort

    if mappings.first.before
      mappings.unshift(mappings.first.before)
    end

    mappings.push(mappings.last.after)

    Map.new(label.chomp(":"), mappings)
  end
end

def seeds_from_input(input)
  seeds_input, _ = input.split(/\n{2,}/)
  seeds_input.split(": ").last.split(" ").map(&:to_i)
end

def lowest_location_number(seed_ranges, maps)
  current_seed_ranges = seed_ranges

  maps.each do |map|
    current_seed_ranges = map.mappings.flat_map do |mapping|
      current_seed_ranges.filter_map do |seed_range|
        mapping.map_range(seed_range)
      end
    end
  end

  current_seed_ranges.map(&:start).min
end

def part_one(input)
  seeds = seeds_from_input(input)
  maps = maps_from_input(input)

  seed_ranges = seeds.map { |seed| SeedRange.new(seed, seed) }

  lowest_location_number(seed_ranges, maps)
end

def part_two(input)
  seeds = seeds_from_input(input)
  maps = maps_from_input(input)

  seed_ranges = seeds.each_slice(2).map { |start, length| SeedRange.new(start, start + length - 1) }

  lowest_location_number(seed_ranges, maps)
end

def main
  puts("part one sample: #{part_one(File.read("inputs/five.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/five.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/five.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/five.txt"))}")
end

main if $0 == __FILE__
