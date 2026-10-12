# frozen_string_literal: true

class Components::V2::ContextMenu::Group < Components::V2::Base
  include Components::V2::ContextMenu::Support

  def initialize(as_child: false, **attrs)
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    attrs = verbatim_class(merge_attrs({ role: "group", data: { slot: "context-menu-group" } }, @attrs), @attrs)
    render_part(:div, @as_child, attrs, &)
  end
end
