# frozen_string_literal: true

# shadcn SidebarTrigger: a ghost icon Button that toggles the sidebar. The children are fixed (icon + sr-only label).
class Components::V2::Sidebar::Trigger < Components::V2::Base
  include Components::V2::Sidebar::Support

  def initialize(variant: "ghost", size: "icon", **attrs)
    # The Button Slot would receive two children (icon + label) and throw (slot:38-47).
    raise ArgumentError, "Sidebar::Trigger cannot take as_child; it renders two children" if attrs.key?(:as_child)

    @variant = variant
    @size = size
    @attrs = attrs
    super()
  end

  def view_template
    Components::V2::Sidebar.use_sidebar(self)
    attrs = with_toggle(canonical_attrs(@attrs).except(:class))
    attrs = attrs.merge(data: { sidebar: "trigger", slot: "sidebar-trigger" }.merge(attrs[:data]))
    render Components::V2::Button.new(variant: @variant, size: @size, class: cn("size-7", @attrs[:class]), **attrs) do
      render Components::V2::Icon.new("panel-left")
      span(class: "sr-only") { "Toggle Sidebar" }
    end
  end
end
