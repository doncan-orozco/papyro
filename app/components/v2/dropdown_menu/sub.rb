# frozen_string_literal: true

# Radix MenuSub: renders no element. open: non-nil is controlled, like the root.
class Components::V2::DropdownMenu::Sub < Components::V2::Base
  include Components::V2::DropdownMenu::Support

  def initialize(open: nil, default_open: false)
    @controlled = !open.nil?
    @open = @controlled ? open : default_open
    super()
  end

  def view_template
    root = root_context
    previous = context[Components::V2::DropdownMenu::SUB_KEY]
    base = "#{root[:base]}-sub-#{Components::V2::DropdownMenu.next_sequence(context)}"
    context[Components::V2::DropdownMenu::SUB_KEY] = {
      trigger_id: "#{base}-trigger", content_id: "#{base}-content", open: @open, controlled: @controlled
    }
    yield if block_given?
  ensure
    context[Components::V2::DropdownMenu::SUB_KEY] = previous
  end
end
