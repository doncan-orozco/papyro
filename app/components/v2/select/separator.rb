# frozen_string_literal: true

class Components::V2::Select::Separator < Components::V2::Base
  include Components::V2::Select::Support

  CLASSES = "pointer-events-none -mx-1 my-1 h-px bg-border"

  def initialize(as_child: false, **attrs)
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    attrs = merge_attrs({ class: CLASSES, aria: { hidden: "true" }, data: { slot: "select-separator" } }, @attrs)
    render_part(:div, @as_child, attrs, &)
  end
end
