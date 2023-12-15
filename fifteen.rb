def focusing_power(boxes)
  boxes.sum do |box, lenses|
    lenses.each_with_index.sum do |lens, slot|
      (1 + box) * (1 + slot) * lens[:focal_length]
    end
  end
end

def organize(steps)
  steps.map { |step| step_operation(step) }.each_with_object({}) do |operation, boxes|
    op, box, label = operation.values_at(:op, :box, :label)

    case op
    when :replace_or_add
      new_lens = {label: label, focal_length: operation[:focal_length]}

      if boxes[box]
        if boxes[box].any? { |lens| lens[:label] == label }
          boxes[box]
            .map! do |lens|
              if lens[:label] == label
                new_lens
              else
                lens
              end
            end
            .compact!
        else
          boxes[box].push(new_lens)
        end
      else
        boxes[box] = [new_lens]
      end

    when :remove
      if boxes[box]
        boxes[box]
          .map! do |lens|
            if lens[:label] == label
              nil
            else
              lens
            end
          end
          .compact!
      end
    end
  end
end

def step_operation(step)
  box = box_for_step(step)

  if step.match?(/=/)
    label, focal_length = step.split("=")

    {
      op: :replace_or_add,
      focal_length: focal_length.to_i,
      label: label,
      box: box
    }
  else
    label = step.split("-").first

    {
      op: :remove,
      box: box,
      label: label
    }
  end
end

def box_for_step(step)
  compute_hash(step.scan(/\A[a-z]+/).first)
end

def compute_hash(s)
  s.each_byte.reduce(0) { |r, i| ((r + i) * 17) % 256 }
end

def part_one(input)
  input.split(",").sum { |step| compute_hash(step) }
end

def part_two(input)
  focusing_power(organize(input.split(",")))
end

def main
  puts("part one sample: #{part_one(File.read("inputs/fifteen.sample.txt"))}")
  puts("part one: #{part_one(File.read("inputs/fifteen.txt"))}")

  puts("part two sample: #{part_two(File.read("inputs/fifteen.sample.txt"))}")
  puts("part two: #{part_two(File.read("inputs/fifteen.txt"))}")
end

main if $0 == __FILE__
