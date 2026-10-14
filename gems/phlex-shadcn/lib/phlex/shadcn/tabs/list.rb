# frozen_string_literal: true

# shadcn TabsList: Radix List over the roving focus group.
#
# @example
#   tabs.list(variant: "line") { tabs.trigger(value: "a") { "A" } }
class Phlex::Shadcn::Tabs::List < Phlex::Shadcn::Base
  include Phlex::Shadcn::Tabs::Support

  # @param variant [String, Symbol] `"default"` or `"line"`
  # @param loop [Boolean] whether keyboard navigation wraps around
  # @param as_child [Boolean, Phlex::Shadcn::Base, Symbol] render onto the given child instead of a `div`
  # @param attrs [Hash] HTML attributes merged onto the list (`style:` is joined after the outline reset)
  def initialize(variant: "default", loop: true, as_child: false, **attrs)
    @variant = normalize_option(variant) || "default"
    @loop = loop
    @as_child = as_child
    @style = attrs.delete(:style)
    @attrs = attrs
    super()
  end

  # @return [void]
  def view_template(&)
    root = root_context
    attrs = merge_attrs({
                          role: "tablist",
                          tabindex: 0,
                          style: join_style("outline: none", @style),
                          class: Phlex::Shadcn::Tabs.list_variants(variant: @variant),
                          aria: { orientation: root[:orientation] },
                          data: { orientation: root[:orientation], slot: "tabs-list", variant: @variant,
                                  shadcn__tabs_target: "list", shadcn__tabs_loop_value: @loop.to_s }
                        }, @attrs)
    render_part(:div, @as_child, attrs, &)
  end
end
