# frozen_string_literal: true

# shadcn SidebarMenu.
class Components::V2::Sidebar::Menu < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = "flex w-full min-w-0 flex-col gap-1"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    tag(:ul, **part_attrs(CLASSES, data: { slot: "sidebar-menu", sidebar: "menu" }), &)
  end
end
