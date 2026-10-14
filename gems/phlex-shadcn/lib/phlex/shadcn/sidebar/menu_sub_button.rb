# frozen_string_literal: true

# shadcn SidebarMenuSubButton (an `a` without href unless given).
#
# Rendered inside a {Phlex::Shadcn::Sidebar}; also available as `sidebar.menu_sub_button` on the yielded sidebar.
#
# @see Phlex::Shadcn::Sidebar
class Phlex::Shadcn::Sidebar::MenuSubButton < Phlex::Shadcn::Base
  include Phlex::Shadcn::Sidebar::Support

  # Accepted `size:` values.
  SIZES = %w[sm md].freeze
  # Tailwind classes shared by every size (verbatim from shadcn/ui).
  CLASSES = [
    "flex h-7 min-w-0 -translate-x-px items-center gap-2 overflow-hidden rounded-md px-2 text-sidebar-foreground ring-sidebar-ring outline-hidden hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0 [&>svg]:text-sidebar-accent-foreground",
    "data-[active=true]:bg-sidebar-accent data-[active=true]:text-sidebar-accent-foreground"
  ].freeze
  # Text size class per size.
  SIZE_CLASSES = { "sm" => "text-xs", "md" => "text-sm" }.freeze

  # @param as_child [Boolean, Symbol, Phlex::Shadcn::Base] render this child (or tag symbol) instead of the `a`, merging the
  #   part attributes onto it like Radix Slot (default: false)
  # @param size [String, Symbol] one of `sm`, `md` (default: "md")
  # @param is_active [Boolean] mark the button as the current page (`data-active`) (default: false)
  # @param attrs [Hash] HTML attributes for the element; `class:` is tailwind-merged over the defaults, `data:` and `aria:`
  #   are deep-merged (caller wins).
  # @raise [ArgumentError] when `size` is unknown
  def initialize(as_child: false, size: "md", is_active: false, **attrs)
    @as_child = as_child
    @size = normalize_option(size) || "md"
    raise ArgumentError, "unknown size: #{size.inspect} (expected one of #{SIZES.join(', ')})" unless SIZES.include?(@size)

    @is_active = is_active
    @attrs = attrs
    super()
  end

  # Renders the `a` (or the `as_child` child) and yields the block as its content.
  def view_template(&)
    classes = cn(CLASSES, SIZE_CLASSES.fetch(@size), "group-data-[collapsible=icon]:hidden")
    render_part(:a, @as_child,
                part_attrs(classes, data: { slot: "sidebar-menu-sub-button", sidebar: "menu-sub-button", size: @size, active: @is_active.to_s }), &)
  end
end
