# frozen_string_literal: true

# shadcn SidebarMenuItem.
class Components::V2::Sidebar::MenuItem < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = "group/menu-item relative"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    tag(:li, **part_attrs(CLASSES, data: { slot: "sidebar-menu-item", sidebar: "menu-item" }), &)
  end
end
