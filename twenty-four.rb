def parse_input(input)
  input.lines.map do |line|
    line.strip.split(" @ ").map do |part|
      part.split(", ").map(&:to_i)
    end
  end
end

def find_segment_intersection(l1, l2)
  (x1, y1), (x2, y2) = l1
  (x3, y3), (x4, y4) = l2

  p_x_numerator = (((x1 * y2) - (y1 * x2)) * (x3 - x4)) - ((x1 - x2) * ((x3 * y4) - (y3 * x4)))
  p_x_denominator = ((x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4))

  p_y_numerator = (((x1 * y2) - (y1 * x2)) * (y3 - y4)) - ((y1 - y2) * ((x3 * y4) - (y3 * x4)))
  p_y_denominator = ((x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4))

  [p_x_numerator / p_x_denominator, p_y_numerator / p_y_denominator]
end

def determine_future_xy_crossings(hailstones, min:, max:)
  hailstones.combination(2).filter_map do |(apos, avel), (bpos, bvel)|
    (ax, ay, _) = apos
    (avx, avy, _) = avel
    (bx, by, _) = bpos
    (bvx, bvy, _) = bvel

    min_ax_intersect = (min - ax).to_f / avx
    max_ax_intersect = (max - ax).to_f / avx
    min_ay_intersect = (min - ay).to_f / avy
    max_ay_intersect = (max - ay).to_f / avy

    min_bx_intersect = (min - bx).to_f / bvx
    max_bx_intersect = (max - bx).to_f / bvx
    min_by_intersect = (min - by).to_f / bvy
    max_by_intersect = (max - by).to_f / bvy

    ax_segment = [min_ax_intersect, max_ax_intersect].map do |t|
      [ax + (avx * t), ay + (avy * t)]
    end

    ay_segment = [min_ay_intersect, max_ay_intersect].map do |t|
      [ax + (avx * t), ay + (avy * t)]
    end

    bx_segment = [min_bx_intersect, max_bx_intersect].map do |t|
      [bx + (bvx * t), by + (bvy * t)]
    end

    by_segment = [min_by_intersect, max_by_intersect].map do |t|
      [bx + (bvx * t), by + (bvy * t)]
    end

    x_intersection = find_segment_intersection(ax_segment, bx_segment)
    y_intersection = find_segment_intersection(ay_segment, by_segment)

    ix1, iy1 = x_intersection
    ix2, iy2 = y_intersection

    if ((ix1 - ax) / avx) > 0 &&
        ((ix1 - bx) / bvx) > 0 &&
        ((ix2 - ax) / avx) > 0 &&
        ((ix2 - bx) / bvx) > 0 &&
        ((iy1 - ay) / avy) > 0 &&
        ((iy1 - by) / bvy) > 0 &&
        ((iy2 - ay) / avy) > 0 &&
        ((iy2 - by) / bvy) > 0
      [x_intersection, y_intersection]
    end
  end
end

def part_one(input, min:, max:)
  hailstones = parse_input(input)
  determine_future_xy_crossings(hailstones, min: min, max: max)
    .select { |coordinates| coordinates.all? { |coordinate| coordinate.all? { |n| n.between?(min, max) } } }
    .count
end

def part_two(input)
  hailstones = parse_input(input)
  velocities = hailstones.map(&:last)
  axes = %w[x y z].each.with_index.to_h

  velocity_spans_by_axis = axes.transform_values do |i|
    velocities.map { |velocity| velocity[i] }.then { |collection| collection.max - collection.min }.then { |length| -(2 * length)..(2 * length) }
  end

  rock_velocity_guesses = [nil, nil, nil]

  pairs = hailstones.combination(2).to_a

  pairs.each do |(p_a, v_a), (p_b, v_b)|
    axes.each do |axis, i|
      position_difference = p_b[i] - p_a[i]
      velocity_span = velocity_spans_by_axis.fetch(axis)

      if v_a[i] == v_b[i]
        possible_velocities = velocity_span.select do |velocity|
          velocity != 0 && velocity != v_a[i] && (position_difference % (velocity - v_a[i])) == 0
        end
      else
        possible_velocities = Set.new
      end

      if possible_velocities.any?
        rock_velocity_guesses[i] ||= possible_velocities
        rock_velocity_guesses[i] &= possible_velocities
      end
    end

    break if rock_velocity_guesses.all? { |v| v&.length == 1 }
  end

  if rock_velocity_guesses.any?(&:nil?)
    raise "something went wrong"
  end

  rock_velocity_guesses[0]
    .flat_map do |v_r_x|
      rock_velocity_guesses[1].flat_map do |v_r_y|
        rock_velocity_guesses[2].flat_map do |v_r_z|
          pairs.filter_map do |(p_a, v_a), (p_b, v_b)|
            v_r = [v_r_x, v_r_y, v_r_z]

            next if v_a[0] == v_r[0]
            next if v_b[0] == v_r[0]

            m_a = (v_a[1].to_f - v_r[1].to_f) / (v_a[0].to_f - v_r[0].to_f)
            m_b = (v_b[1].to_f - v_r[1].to_f) / (v_b[0].to_f - v_r[0].to_f)

            next if m_a == m_b

            p_r_x = ((p_b[1].to_f - (m_b.to_f * p_b[0].to_f)) - (p_a[1].to_f - (m_a.to_f * p_a[0].to_f))) / (m_a.to_f - m_b.to_f)

            t = (p_r_x.to_f - p_a[0].to_f) / (v_a[0].to_f - v_r[0].to_f)

            p_r_y = p_a[1].to_f + (t.to_f * (v_a[1].to_f - v_r[1].to_f))
            p_r_z = p_a[2].to_f + (t.to_f * (v_a[2].to_f - v_r[2].to_f))

            [[p_r_x, p_r_y, p_r_z].map(&:round), v_r]
          end
        end
      end
      # => [p, v] => count => sort => map to key => last (highest count) => position => sum
    end
    .tally
    .sort_by(&:last)
    .map(&:first)
    .last
    .first
    .sum
end

def main
  sample_input = File.read("inputs/twenty-four.sample.txt")
  input = File.read("inputs/twenty-four.txt")

  puts("part one sample: #{part_one(sample_input, min: 7, max: 27)}")
  puts("part one: #{part_one(input, min: 200000000000000, max: 400000000000000)}")

  puts("part two sample: #{part_two(sample_input)}")
  puts("part two: #{part_two(input)}")
end

main if $0 == __FILE__
