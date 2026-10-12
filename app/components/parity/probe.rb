# frozen_string_literal: true

# Stub component that proves the parity harness before any real component uses it. React twin: src/parity/probes.tsx.
# Broken-probe self-test: while tmp/shadcn-port/_harness/break-probe exists, an extra class is rendered (the runner must fail).
class Components::Parity::Probe < Components::V2::Base
  VARIANTS = {
    "default" => "bg-primary text-primary-foreground",
    "outline" => "border bg-background text-foreground"
  }.freeze
  BREAK_FLAG = "tmp/shadcn-port/_harness/break-probe"

  def initialize(variant: "default", as_child: false, **attrs)
    @variant = variant.to_s
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    attrs = merge_attrs({
      class: [ "inline-flex items-center gap-1 rounded-md px-2 py-1 text-sm font-medium [&_svg:not([class*='size-'])]:size-4", VARIANTS[@variant], broken_class ],
      data: { slot: "probe", variant: @variant }
    }, @attrs)
    return render_as_child(@as_child, **attrs, &) if @as_child

    span(**attrs, &)
  end

  private

  def broken_class
    "underline" if Rails.root.join(BREAK_FLAG).exist?
  end
end
