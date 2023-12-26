def parse_rules(rules_input)
  rules = rules_input.split(",").map do |rule_input|
    case rule_input
    when /:/
      component, sign, number_s, destination = rule_input.scan(/([xmas])([<>])(\d+):([a-zA-Z]+)/).first
      number = number_s.to_i

      {
        check_part: -> (part) {
          actual = part[component]

          case sign
          when "<"
            actual < number
          when ">"
            actual > number
          else
            raise "unexpected sign #{sign}"
          end
        },
        check_range: -> (part) {
          range = part[component]

          case sign
          when "<"
            if number <= range.min
              matching_range = 0...0
              skipping_range = range
            else
              matching_range = Range.new(*[range.min, number].sort, true)
              skipping_range = Range.new(*[number, range.max].sort, false)
            end

          when ">"
            if number >= range.max
              matching_range = 0...0
              skipping_range = range
            else
              matching_range = Range.new(*[number.succ, range.max].sort, false)
              skipping_range = Range.new(*[number, range.min].sort, false)
            end
          else
            raise "unexpected sign #{sign}"
          end

          {
            in: part.merge(component => matching_range),
            out: part.merge(component => skipping_range)
          }.reject do |_, modified_part|
            modified_part[component].count == 0
          end
        },
        component: component,
        destination: destination,
        number: number,
        sign: sign
      }
    else
      {destination: rule_input, check_part: -> (part) { true }, check_range: -> (part) { {in: part} }}
    end
  end

  {rules: rules}
end

def parse_script(script_input)
  script_input.lines.to_h do |line|
    routine, rules_input = line.strip.scan(/([^{]+)\{([^{]+)\}/).first

    [
      routine,
      parse_rules(rules_input)
    ]
  end
end

def parse_parts(input)
  input.lines.map do |line|
    line.strip.scan(/([xmas])=(\d+)/).to_h.transform_values(&:to_i)
  end
end

def evaluate_parts(script, parts)
  parts.to_h do |part|
    result = nil
    workflows = ["in"]

    while result.nil?
      workflow = workflows.shift

      rules = script[workflow][:rules]

      matching_rule = rules.find do |rule|
        rule[:check_part].call(part)
      end

      destination = matching_rule[:destination]

      case destination
      when "R", "A"
        result = destination
      else
        workflows << destination
      end
    end

    [part, result]
  end
end

def determine_acceptable_parts(script)
  base = %w[x m a s].to_h { |c| [c, (1..4000)] }
  queue = [[base, "in"]]
  results = {}

  while queue.any?
    part_spec, workflow = queue.shift
    workflows = [workflow]
    result = nil

    while result.nil?
      workflow = workflows.shift
      destination = nil

      rules = script[workflow][:rules]

      matching_rule = rules.find do |rule|
        rule[:check_range].call(part_spec).key?(:in)
      end

      rule_result = matching_rule[:check_range].call(part_spec)
      destination = matching_rule[:destination]

      # replace initial part_spec with the narrowed part_spec
      part_spec = rule_result[:in]

      if rule_result[:out]
        # verify range splitting logic
        if matching_rule[:check_range].call(rule_result[:out]).keys.include?(:in)
          raise ":out should not be in the range we just checked"
        end

        queue << [rule_result[:out], workflow]
      end

      case destination
      when "R", "A"
        result = destination
      when String
        workflows << destination
      else
        raise "didn't get a destination"
      end
    end

    results[part_spec] = result
  end

  results
end

def part_one(input)
  script_input, parts_input = input.split(/\n{2}/)

  script = parse_script(script_input)
  parts = parse_parts(parts_input)

  results = evaluate_parts(script, parts)

  results.select { |k, v| v == "A" }.keys.flat_map(&:values).sum
end

def part_two(input)
  script_input, _ = input.split(/\n{2}/)

  script = parse_script(script_input)

  results = determine_acceptable_parts(script)

  results.select { |k, v| v == "A" }.keys.sum do |spec|
    spec.values.map(&:count).reduce(&:*)
  end
end

def main
  puts("part one sample: #{part_one(File.read("inputs/nineteen.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/nineteen.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/nineteen.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/nineteen.txt"))}")
end

main if $0 == __FILE__
