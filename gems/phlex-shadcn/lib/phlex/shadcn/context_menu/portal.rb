# frozen_string_literal: true

# Radix MenuPortal: renders no element. Only meaningful around SubContent (Content already portals itself); it tells
# SubContent to mount in container: (a CSS selector, default body) instead of in place.
# Radix MenuPortal: renders no element. Only meaningful around {SubContent} (+Content+ already portals itself): it tells the
# SubContent to mount in +container+ (a CSS selector, default +body+) instead of in place. It reaches only the SubContent directly
# inside it; sub menus nested in that SubContent need a Portal of their own. It does not require a surrounding root.
#
# @example
#   menu.portal(container: "#overlays") { menu.sub_content { menu.item { "Save" } } }
class Phlex::Shadcn::ContextMenu::Portal < Phlex::Shadcn::Base
  # @param force_mount [Boolean] makes the wrapped SubContent force-mounted (default +false+)
  # @param container [String, nil] CSS selector of the element the SubContent mounts into; +nil+ (default) mounts it in +body+
  def initialize(force_mount: false, container: nil)
    @force_mount = force_mount
    @container = container
    super()
  end

  # @yield the parts rendered inside the portal (a SubContent)
  # @return [void]
  def view_template
    previous = context[Phlex::Shadcn::ContextMenu::PORTAL_KEY]
    context[Phlex::Shadcn::ContextMenu::PORTAL_KEY] = { force_mount: @force_mount, container: @container }
    yield if block_given?
  ensure
    context[Phlex::Shadcn::ContextMenu::PORTAL_KEY] = previous
  end
end
