# frozen_string_literal: true

# shadcn SidebarHeader.
class Components::V2::Sidebar::Header < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = "flex flex-col gap-2 p-2"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    tag(:div, **part_attrs(CLASSES, data: { slot: "sidebar-header", sidebar: "header" }), &)
  end
end
