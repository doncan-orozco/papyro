# frozen_string_literal: true

# shadcn TabsList: Radix List over the roving focus group.
class Components::V2::Tabs::List < Components::V2::Base
  include Components::V2::Tabs::Support

  def initialize(variant: "default", loop: true, as_child: false, **attrs)
    @variant = normalize_option(variant) || "default"
    @loop = loop
    @as_child = as_child
    @style = attrs.delete(:style)
    @attrs = attrs
    super()
  end

  def view_template(&)
    root = root_context
    attrs = merge_attrs({
      role: "tablist",
      tabindex: 0,
      style: join_style("outline: none", @style),
      class: Components::V2::Tabs.list_variants(variant: @variant),
      aria: { orientation: root[:orientation] },
      data: { orientation: root[:orientation], slot: "tabs-list", variant: @variant,
              v2__tabs_target: "list", v2__tabs_loop_value: @loop.to_s }
    }, @attrs)
    render_part(:div, @as_child, attrs, &)
  end
end
