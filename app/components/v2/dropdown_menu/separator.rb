# frozen_string_literal: true

class Components::V2::DropdownMenu::Separator < Components::V2::Base
  include Components::V2::DropdownMenu::Support

  CLASSES = "-mx-1 my-1 h-px bg-border"

  def initialize(as_child: false, **attrs)
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    attrs = merge_attrs({ role: "separator", class: CLASSES, aria: { orientation: "horizontal" }, data: { slot: "dropdown-menu-separator" } }, @attrs)
    render_part(:div, @as_child, attrs, &)
  end
end
