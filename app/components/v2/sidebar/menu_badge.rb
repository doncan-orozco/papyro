# frozen_string_literal: true

# shadcn SidebarMenuBadge.
class Components::V2::Sidebar::MenuBadge < Components::V2::Base
  include Components::V2::Sidebar::Support

  CLASSES = [
    "pointer-events-none absolute right-1 flex h-5 min-w-5 items-center justify-center rounded-md px-1 text-xs font-medium text-sidebar-foreground tabular-nums select-none",
    "peer-hover/menu-button:text-sidebar-accent-foreground peer-data-[active=true]/menu-button:text-sidebar-accent-foreground",
    "peer-data-[size=sm]/menu-button:top-1",
    "peer-data-[size=default]/menu-button:top-1.5",
    "peer-data-[size=lg]/menu-button:top-2.5",
    "group-data-[collapsible=icon]:hidden"
  ].freeze

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    div(**part_attrs(cn(CLASSES), data: { slot: "sidebar-menu-badge", sidebar: "menu-badge" }), &)
  end
end
