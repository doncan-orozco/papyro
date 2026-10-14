# frozen_string_literal: true

# Radix SelectScrollUpButton: Content renders one automatically, explicit ones go inside the viewport. The controller keeps
# the node out of the document until the viewport can scroll up (sel:L976-1065).
#
# Chevron-up button shown by the controller when the viewport can scroll up.
#
# @example
#   select.scroll_up_button
class Phlex::Shadcn::Select::ScrollUpButton < Phlex::Shadcn::Base
  include Phlex::Shadcn::Select::Support

  # @return [String] Tailwind classes of the button
  CLASSES = "flex cursor-default items-center justify-center py-1"

  # @param attrs [Hash] HTML attributes merged into the element (+class+ is merged with Tailwind conflict resolution, +data+/+aria+ deep-merged, caller wins)
  # @return [void]
  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  # @return [void]
  def view_template
    attrs = merge_attrs({ aria: { hidden: "true" }, class: CLASSES, style: "flex-shrink: 0;", data: { slot: "select-scroll-up-button" } },
                        @attrs)
    div(**attrs) { render Phlex::Shadcn::Icon.new("chevron-up", class: "size-4") }
  end
end
