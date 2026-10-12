# frozen_string_literal: true

# shadcn Empty (new-york-v4). Spec: docs/shadcn-port/specs/empty.md. Static: no controller.
class Components::V2::Empty < Components::V2::Base
  CLASS_NAME = "flex min-w-0 flex-1 flex-col items-center justify-center gap-6 rounded-lg border-dashed p-6 text-center text-balance md:p-12"

  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&block)
    div(**merge_attrs({ data: { slot: "empty" }, class: CLASS_NAME }, @attrs)) { yield self if block }
  end

  class Header < Components::V2::Base
    CLASS_NAME = "flex max-w-sm flex-col items-center gap-2 text-center"

    def initialize(**attrs)
      @attrs = attrs
      super()
    end

    def view_template(&)
      div(**merge_attrs({ data: { slot: "empty-header" }, class: CLASS_NAME }, @attrs), &)
    end
  end

  class Media < Components::V2::Base
    BASE = "mb-2 flex shrink-0 items-center justify-center [&_svg]:pointer-events-none [&_svg]:shrink-0"

    VARIANTS = {
      "default" => "bg-transparent",
      "icon" => "flex size-10 shrink-0 items-center justify-center rounded-lg bg-muted text-foreground [&_svg:not([class*='size-'])]:size-6"
    }.freeze

    # React `emptyMediaVariants`.
    def self.variants(variant: "default", class: nil)
      new(variant: variant).send(:classes, binding.local_variable_get(:class))
    end

    def initialize(variant: "default", **attrs)
      @variant = normalize_option(variant) || "default"
      raise ArgumentError, "unknown variant: #{variant.inspect} (expected one of #{VARIANTS.keys.join(", ")})" unless VARIANTS.key?(@variant)

      @attrs = attrs
      super()
    end

    def view_template(&)
      div(**merge_attrs({ data: { slot: "empty-icon", variant: @variant }, class: classes }, @attrs), &)
    end

    private

    def classes(extra = nil) = cn(BASE, VARIANTS[@variant], extra)
  end

  class Title < Components::V2::Base
    CLASS_NAME = "text-lg font-medium tracking-tight"

    def initialize(**attrs)
      @attrs = attrs
      super()
    end

    def view_template(&)
      div(**merge_attrs({ data: { slot: "empty-title" }, class: CLASS_NAME }, @attrs), &)
    end
  end

  class Description < Components::V2::Base
    CLASS_NAME = "text-sm/relaxed text-muted-foreground [&>a]:underline [&>a]:underline-offset-4 [&>a:hover]:text-primary"

    def initialize(**attrs)
      @attrs = attrs
      super()
    end

    def view_template(&)
      div(**merge_attrs({ data: { slot: "empty-description" }, class: CLASS_NAME }, @attrs), &)
    end
  end

  class Content < Components::V2::Base
    CLASS_NAME = "flex w-full max-w-sm min-w-0 flex-col items-center gap-4 text-sm text-balance"

    def initialize(**attrs)
      @attrs = attrs
      super()
    end

    def view_template(&)
      div(**merge_attrs({ data: { slot: "empty-content" }, class: CLASS_NAME }, @attrs), &)
    end
  end
end
