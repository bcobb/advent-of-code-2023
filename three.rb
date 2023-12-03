class JoinedNumber
  def initialize(value:, coordinates:)
    @value = value
    @coordinates = coordinates
  end

  attr_reader :value

  def occupies?(coordinate)
    @coordinates.include?(coordinate)
  end
end

class Searcher
  def self.from_input(input)
    grid = input.lines.map(&:strip).map(&:chars)
    symbol_coordinates = []
    numeral_coordinates = []
    gear_coordinates = []

    grid.each.with_index do |row_values, row_index|
      row_values.each.with_index do |row_value, column_index|
        if !row_value.match?(/\d|\./)
          symbol_coordinates << [row_index, column_index]

          if row_value == "*"
            gear_coordinates << [row_index, column_index]
          end
        elsif row_value.match?(/\d/)
          numeral_coordinates << [row_index, column_index]
        end
      end
    end

    Searcher.new(
      grid: grid,
      numeral_coordinates: numeral_coordinates,
      symbol_coordinates: symbol_coordinates,
      gear_coordinates: gear_coordinates
    )
  end

  def initialize(grid:, numeral_coordinates:, symbol_coordinates:, gear_coordinates:)
    @search_adjustments = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1]
    ]
    @grid = grid
    @numeral_coordinates = numeral_coordinates
    @symbol_coordinates = symbol_coordinates
    @gear_coordinates = gear_coordinates
    @buffer = []
  end

  def locate_gear_ratios
    numbers = locate_numbers

    @gear_coordinates.filter_map do |gear_coordinate|
      search_coordinates = @search_adjustments.map do |adjustments|
        adjustments.zip(gear_coordinate).map(&:sum)
      end

      relevant_numbers = numbers.select do |number|
        search_coordinates.any? { |search_coordinate| number.occupies?(search_coordinate) }
      end

      relevant_numbers.length == 2 && relevant_numbers.map(&:value).reduce(&:*)
    end
  end

  def locate_numbers
    queue = @numeral_coordinates.dup
    numbers = []

    while queue.any?
      current_coordinate = queue.shift
      current_row, current_column = current_coordinate

      if @buffer.empty?
        @buffer << {coordinate: current_coordinate, value: @grid[current_row][current_column]}
      else
        previous_row, previous_column = @buffer.last[:coordinate]

        if previous_row == current_row && previous_column == (current_column - 1)
          @buffer << {coordinate: current_coordinate, value: @grid[current_row][current_column]}
        else
          maybe_harvest_number! { |result| numbers << result }

          @buffer << {coordinate: current_coordinate, value: @grid[current_row][current_column]}
        end
      end
    end

    maybe_harvest_number! { |result| numbers << result }

    numbers
  end

  private def maybe_harvest_number!
    search_coordinates = @buffer.flat_map do |b|
      @search_adjustments.map do |adjustments|
        adjustments.zip(b[:coordinate]).map(&:sum)
      end
    end

    if (@symbol_coordinates & search_coordinates).any?
      yield JoinedNumber.new(value: @buffer.map { |b| b[:value] }.join.to_i, coordinates: @buffer.map { |b| b[:coordinate] })
    end

    @buffer.clear
  end
end

def part_one(input)
  searcher = Searcher.from_input(input)
  numbers = searcher.locate_numbers
  numbers.sum(&:value)
end

def part_two(input)
  searcher = Searcher.from_input(input)
  gear_ratios = searcher.locate_gear_ratios
  gear_ratios.sum
end

def main
  puts("part one sample: #{part_one(File.read("inputs/three.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/three.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/three.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/three.txt"))}")
end

main if $0 == __FILE__
