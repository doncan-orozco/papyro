# frozen_string_literal: true

class Components::V2::DropdownMenu::Group < Components::V2::Base
  include Components::V2::DropdownMenu::Support

  def initialize(as_child: false, **attrs)
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    render_part(:div, @as_child, merge_attrs({ role: "group", data: { slot: "dropdown-menu-group" } }, @attrs), &)
  end
end
