# frozen_string_literal: true

# shadcn SidebarHeader.
#
# Rendered inside a {Phlex::Shadcn::Sidebar}; also available as `sidebar.header` on the yielded sidebar.
#
# @see Phlex::Shadcn::Sidebar
class Phlex::Shadcn::Sidebar::Header < Phlex::Shadcn::Base
  include Phlex::Shadcn::Sidebar::Support

  # Tailwind classes of the `div` (verbatim from shadcn/ui).
  CLASSES = "flex flex-col gap-2 p-2"

  # @param attrs [Hash] HTML attributes for the element; `class:` is tailwind-merged over the defaults, `data:` and `aria:`
  #   are deep-merged (caller wins).
  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  # Renders the `div` and yields the block as its content.
  def view_template(&)
    tag(:div, **part_attrs(CLASSES, data: { slot: "sidebar-header", sidebar: "header" }), &)
  end
end
