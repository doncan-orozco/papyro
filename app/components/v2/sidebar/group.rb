# frozen_string_literal: true

# shadcn SidebarGroup.
class Components::V2::Sidebar::Group < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = "relative flex w-full min-w-0 flex-col p-2"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    tag(:div, **part_attrs(CLASSES, data: { slot: "sidebar-group", sidebar: "group" }), &)
  end
end
