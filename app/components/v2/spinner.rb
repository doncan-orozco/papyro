# frozen_string_literal: true

# shadcn `Spinner` (new-york-v4). Spec: docs/shadcn-port/specs/spinner.md. Static: no controller, no data-slot.
class Components::V2::Spinner < Components::V2::Base
  def initialize(**attrs)
    @attrs = attrs
  end

  def view_template(&block)
    attrs = @attrs.dup
    # lucide Icon consumes `color` as the stroke attribute instead of forwarding it.
    attrs[:stroke] = attrs.delete(:color) if attrs.key?(:color)
    # lucide omits aria-hidden when role/aria props are present; Spinner always passes both.
    defaults = { role: "status", aria: { label: "Loading", hidden: nil }, class: "size-4 animate-spin" }
    render Components::V2::Icon.new("loader-circle", **merge_attrs(defaults, attrs)), &block
  end
end
