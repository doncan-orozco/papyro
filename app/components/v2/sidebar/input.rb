# frozen_string_literal: true

# shadcn SidebarInput: the shared Input with the sidebar sizing.
class Components::V2::Sidebar::Input < Components::V2::Base
  CLASSES = "h-8 w-full bg-background shadow-none"

  def initialize(type: nil, **attrs)
    @type = type
    @attrs = attrs
    super()
  end

  def view_template
    attrs = canonical_attrs(@attrs).except(:class)
    data = { slot: "sidebar-input", sidebar: "input" }.merge(attrs[:data] || {})
    render Components::V2::Input.new(type: @type, class: cn(CLASSES, @attrs[:class]), **attrs.merge(data:))
  end
end
