class Untyped
  def initialize(label)
    @label = label
  end

  attr_reader :label

  def low(from:)
  end

  def high(from:)
  end
end

class Broadcaster
  def initialize(label, destinations)
    @label = label
    @destinations = destinations
  end

  attr_reader :label

  def low(from:)
    @destinations.map { |destination| {signal: :low, from: @label, to: destination} }
  end

  def high(from:)
    @destinations.map { |destination| {signal: :high, from: @label, to: destination} }
  end
end

class Bus
  def initialize
    @messages = []
    @destinations = {}
  end

  def add(destination_label, destination)
    @destinations[destination_label] = destination
  end

  def publish(message)
    @messages << message
  end

  def process
    next_messages = @messages.flat_map do |message|
      destination = @destinations[message[:to]]
      destination.send(message, from: message[:from])
    end

    @messages.clear
    @messages += next_messages
  end
end

class FlipFlop
  def initialize(label, destination_labels)
    @label = label
    @off = true
    @destination_labels = destination_labels
  end

  attr_reader :label

  def high(from:)
    # noop
  end

  def low(from:)
    signal = @off ? :high : :low
    @off = !@off

    @destination_labels.map do |destination_label|
      {
        from: @label,
        to: destination_label,
        signal: signal
      }
    end
  end
end

class Conjunction
  def initialize(label, destination_labels)
    @label = label
    @destination_labels = destination_labels
    @received = {}
    @sent_high = 0
  end

  attr_reader :label
  attr_reader :sent_high

  def will_receive_from(from)
    @received[from] = :low
  end

  def high(from:)
    @received[from] = :high

    if @received.all? { |k, v| v == :high }
      @destination_labels.map do |destination|
        {from: @label, to: destination, signal: :low}
      end
    else
      send_high
    end
  end

  def low(from:)
    @received[from] = :low

    send_high
  end

  def send_high
    @sent_high += 1
    @destination_labels.map do |destination|
      {from: @label, to: destination, signal: :high}
    end
  end
end

def parse_input(input)
  registry = input
    .lines
    .map(&:strip)
    .map do |line|
      line.split(" -> ")
    end
    .each_with_object({modules: {}, inputs_by_module: {}}) do |(source_label, destinations_input), map|
      destination_labels = destinations_input.split(", ")
      clean_source_label = source_label.gsub(/\W/, "")

      source = case source_label
      when /&/
        Conjunction.new(clean_source_label, destination_labels)
      when /%/
        FlipFlop.new(clean_source_label, destination_labels)
      when /broadcaster/
        Broadcaster.new(clean_source_label, destination_labels)
      else
        raise "got #{source_label}"
      end

      map[:modules][clean_source_label] = source

      destination_labels.each do |destination_label|
        map[:inputs_by_module][destination_label] ||= []
        map[:inputs_by_module][destination_label] << clean_source_label
      end
    end

  registry[:modules]
    .select do |module_name, mod|
      mod.is_a?(Conjunction)
    end
    .each do |module_name, conjunction|
      registry[:inputs_by_module][module_name].each do |input|
        conjunction.will_receive_from(input)
      end
    end

  all_modules = (registry[:inputs_by_module].keys + registry[:inputs_by_module].values.flatten).uniq

  all_modules.each do |module_name|
    if registry[:modules][module_name].nil?
      registry[:modules][module_name] = Untyped.new(module_name)
    end
  end

  registry
end

def push_button(modules_by_label)
  queue = [{from: "button", to: "broadcaster", signal: :low}]

  low_pulses_sent = 0
  high_pulses_sent = 0

  while queue.any?
    current = queue.shift

    case current[:signal]
    when :low
      low_pulses_sent += 1
    when :high
      high_pulses_sent += 1
    end

    # puts("#{current[:from]} -#{current[:signal]}-> #{current[:to]}")

    mod = modules_by_label.fetch(current[:to])

    subsequent_signals = case current[:signal]
    when :low
      mod.low(from: current[:from])
    when :high
      mod.high(from: current[:from])
    else
      raise "unexpected signal #{current[:signal]}"
    end

    queue += Array(subsequent_signals)
  end

  [low_pulses_sent, high_pulses_sent]
end

def part_one(input)
  registry = parse_input(input)
  modules_by_label = registry[:modules]

  low_pulses = 0
  high_pulses = 0

  pulses = 1000.times.each do
    low_add, high_add = push_button(modules_by_label)
    low_pulses += low_add
    high_pulses += high_add
  end

  low_pulses * high_pulses
end

def part_two(input)
  registry = parse_input(input)
  modules_by_label = registry[:modules]
  # jm -> rx

  # sg -> jm
  # lm -> jm
  # dh -> jm
  # db -> jm

  # => if jm receives all highs, it'll send a low to rx

  # find LCM of when all jm inputs are high, assuming they're high at least once
  # within the span of 10k presses

  counts = %w[sg lm dh db].to_h { |k| [k, nil] }

  10_000.times do |i|
    push_button(modules_by_label)

    counts.reject { |_, v| v }.each do |module_name, _|
      if modules_by_label[module_name].sent_high > 0 && counts[module_name].nil?
        counts[module_name] = i + 1
      end
    end
  end

  counts.values.reduce(&:*)
end

def main
  sample_input = File.read("inputs/twenty.sample1.txt")
  input = File.read("inputs/twenty.txt")

  puts("part one sample: #{part_one(sample_input)}")
  puts("part one: #{part_one(input)}")
  puts("part two: #{part_two(input)}")
end

main if $0 == __FILE__
