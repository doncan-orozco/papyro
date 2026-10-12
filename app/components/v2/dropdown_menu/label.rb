# frozen_string_literal: true

class Components::V2::DropdownMenu::Label < Components::V2::Base
  include Components::V2::DropdownMenu::Support

  CLASSES = "px-2 py-1.5 text-sm font-medium data-[inset]:pl-8"

  def initialize(inset: nil, as_child: false, **attrs)
    @inset = inset
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    attrs = merge_attrs({ class: CLASSES, data: { slot: "dropdown-menu-label", inset: inset_value(@inset) } }, @attrs)
    render_part(:div, @as_child, attrs, &)
  end
end
