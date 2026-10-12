# frozen_string_literal: true

# DirectionProvider: pushes the direction into the render context for consumers; emits no markup.
class Components::V2::Direction::Provider < Components::V2::Base
  def initialize(dir: nil, direction: nil)
    value = (direction.nil? ? dir : direction)&.to_s
    unless value.nil? || Components::V2::Direction::VALUES.include?(value)
      raise ArgumentError, "direction must be ltr or rtl, got #{value.inspect}"
    end

    @value = value
    super()
  end

  def view_template
    previous = context[Components::V2::Direction::KEY]
    context[Components::V2::Direction::KEY] = @value
    yield self if block_given?
  ensure
    context[Components::V2::Direction::KEY] = previous
  end
end
