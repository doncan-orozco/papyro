# frozen_string_literal: true

# Radix MenubarMenu: renders no element. value: identifies the menu for the root value; nil gets an auto value from the
# per-render counter (Mb:97-98). Modal is forced off by Radix and is not an option.
class Components::V2::Menubar::Menu < Components::V2::Base
  include Components::V2::Menubar::Support

  def initialize(value: nil)
    @value = value&.to_s
    super()
  end

  def view_template
    root = root_context
    previous = context[Components::V2::Menubar::MENU_KEY]
    base = "#{root[:base]}-menu-#{Components::V2::Menubar.next_sequence(context)}"
    value = @value.presence || base
    context[Components::V2::Menubar::MENU_KEY] = {
      value:, open: root[:value] == value, trigger_id: "#{base}-trigger", content_id: "#{base}-content", base:
    }
    yield if block_given?
  ensure
    context[Components::V2::Menubar::MENU_KEY] = previous
  end
end
