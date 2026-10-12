# frozen_string_literal: true

# shadcn SidebarContent.
class Components::V2::Sidebar::Content < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = "flex min-h-0 flex-1 flex-col gap-2 overflow-auto group-data-[collapsible=icon]:overflow-hidden"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    tag(:div, **part_attrs(CLASSES, data: { slot: "sidebar-content", sidebar: "content" }), &)
  end
end
