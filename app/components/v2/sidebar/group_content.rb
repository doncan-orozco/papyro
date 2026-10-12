# frozen_string_literal: true

# shadcn SidebarGroupContent.
class Components::V2::Sidebar::GroupContent < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = "w-full text-sm"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    tag(:div, **part_attrs(CLASSES, data: { slot: "sidebar-group-content", sidebar: "group-content" }), &)
  end
end
