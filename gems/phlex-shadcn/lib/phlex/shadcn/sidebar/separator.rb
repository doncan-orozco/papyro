# frozen_string_literal: true

# shadcn SidebarSeparator: the shared Separator with the sidebar colors.
#
# Rendered inside a {Phlex::Shadcn::Sidebar}; also available as `sidebar.separator` on the yielded sidebar.
#
# @see Phlex::Shadcn::Sidebar
# @see Phlex::Shadcn::Separator
class Phlex::Shadcn::Sidebar::Separator < Phlex::Shadcn::Base
  # Tailwind classes merged onto the shared Separator (verbatim from shadcn/ui).
  CLASSES = "mx-2 w-auto bg-sidebar-border"

  # @param orientation [String, Symbol] `horizontal` or `vertical` (default: "horizontal")
  # @param decorative [Boolean] purely visual, hidden from assistive technology (default: true)
  # @param as_child [Boolean, Symbol, Phlex::Shadcn::Base] forwarded to {Phlex::Shadcn::Separator} (default: false)
  # @param attrs [Hash] attributes forwarded to {Phlex::Shadcn::Separator}; `class:` is tailwind-merged over the defaults
  def initialize(orientation: "horizontal", decorative: true, as_child: false, **attrs)
    @orientation = orientation
    @decorative = decorative
    @as_child = as_child
    @attrs = attrs
    super()
  end

  # Renders the shared {Phlex::Shadcn::Separator} with the sidebar slot data attributes.
  def view_template(&)
    attrs = canonical_attrs(@attrs).except(:class)
    data = { slot: "sidebar-separator", sidebar: "separator" }.merge(attrs[:data] || {})
    render(Phlex::Shadcn::Separator.new(orientation: @orientation, decorative: @decorative, as_child: @as_child,
                                        class: cn(CLASSES, @attrs[:class]), **attrs.merge(data:)), &)
  end
end
