# frozen_string_literal: true

# Mixin for parts that read the direction (Radix useDirection).
module Components::V2::Direction::Consumer
  private

  def use_direction(local_dir = nil)
    Components::V2::Direction.use_direction(context, local_dir)
  end
end
