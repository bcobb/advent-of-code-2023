class Beam
  def self.direction_to_delta
    @direction_to_delta ||= {
      right: [0, 1],
      left: [0, -1],
      down: [1, 0],
      up: [-1, 0]
    }
  end

  def self.reflections
    @reflections ||= {
      right: {
        "/" => :up,
        "\\" => :down
      },
      left: {
        "/" => :down,
        "\\" => :up
      },
      down: {
        "/" => :left,
        "\\" => :right
      },
      up: {
        "/" => :right,
        "\\" => :left
      }
    }
  end

  def self.splits
    @splits ||= {
      right: {
        "|" => [:up, :down]
      },
      left: {
        "|" => [:up, :down]
      },
      down: {
        "-" => [:left, :right]
      },
      up: {
        "-" => [:left, :right]
      }
    }
  end

  def initialize(grid:, origin:, direction:)
    @max_row = grid.length
    @max_col = grid.first.length
    @grid = grid
    @origin = origin
    @location = origin
    @direction = direction
    @energized_tiles = Set.new([origin])
  end

  attr_reader :energized_tiles
  attr_reader :direction
  attr_reader :location
  attr_reader :origin

  def simulate!
    while on_grid? && sub_beams.empty?
      @energized_tiles << @location

      @location = @location.zip(self.class.direction_to_delta[@direction]).map(&:sum)
    end

    if on_grid?
      @energized_tiles << @location
    end
  end

  def sub_beams
    if on_grid?
      tile = @grid.dig(*@location)

      (Array(self.class.reflections.dig(@direction, tile)) + Array(self.class.splits.dig(@direction, tile))).map do |direction|
        sub_beam_origin = @location.zip(self.class.direction_to_delta[direction]).map(&:sum)

        Beam.new(grid: @grid, origin: sub_beam_origin, direction: direction)
      end
    else
      []
    end
  end

  def empty_space?
    tile = @grid.dig(*@location)

    tile == "." || self.class.splits.dig(@direction, tile).nil?
  end

  def on_grid?
    row, col = @location

    row >= 0 && col >= 0 && row < @max_row && col < @max_col
  end

  def signature
    @origin.hash ^ @direction.hash
  end
end

def count_energized_tiles(grid:, origin:, direction:)
  finished_beams = {}
  running_beams = [Beam.new(grid: grid, origin: origin, direction: direction)]

  while running_beams.any?
    beam = running_beams.shift
    beam.simulate!

    finished_beams[beam.signature] ||= beam

    beam.sub_beams.each do |sub_beam|
      if finished_beams[sub_beam.signature].nil? && sub_beam.on_grid?
        running_beams << sub_beam
      end
    end
  end

  finished_beams.values.map(&:energized_tiles).reduce(&:|).length
end

def max_energized_beams(grid)
  (0...grid.length)
    .filter_map do |row|
      maybe = (0...grid.first.length).filter_map do |col|
        if row == 0 || col == 0 || row == grid.length.pred || col == grid.first.length.pred
          [row, col]
        end
      end

      maybe.any? ? maybe : nil
    end
    .flatten(1)
    .map do |origin|
      [:up, :down, :left, :right]
        .map do |direction|
          count_energized_tiles(grid: grid, origin: origin, direction: direction)
        end
        .max
    end
    .max
end

def input_to_grid(input)
  input.lines.map { |line| line.strip.chars }
end

def part_one(input)
  grid = input_to_grid(input)

  count_energized_tiles(grid: grid, origin: [0, 0], direction: :right)
end

def part_two(input)
  grid = input_to_grid(input)

  max_energized_beams(grid)
end

def main
  puts("part one sample: #{part_one(File.read("inputs/sixteen.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/sixteen.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/sixteen.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/sixteen.txt"))}")
end

main if $0 == __FILE__
