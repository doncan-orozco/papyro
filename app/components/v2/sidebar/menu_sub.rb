# frozen_string_literal: true

# shadcn SidebarMenuSub.
class Components::V2::Sidebar::MenuSub < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = [
    "mx-3.5 flex min-w-0 translate-x-px flex-col gap-1 border-l border-sidebar-border px-2.5 py-0.5",
    "group-data-[collapsible=icon]:hidden"
  ].freeze

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    ul(**part_attrs(cn(CLASSES), data: { slot: "sidebar-menu-sub", sidebar: "menu-sub" }), &)
  end
end
