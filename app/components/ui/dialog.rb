# frozen_string_literal: true

# Dialog (Modal) component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    # Dialog overlay
    class DialogOverlay < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        [
          "fixed inset-0 z-50",
          "bg-black/80",
          "transition-opacity duration-200"
        ].join(" ")
      end
    end

    # Dialog content container
    class DialogContent < Components::Base
      def initialize(labelledby_id: nil, describedby_id: nil, **attrs)
        @labelledby_id = labelledby_id
        @describedby_id = describedby_id
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Set aria-modal unless already provided
        aria_hash = dynamic_attrs[:aria] || {}
        aria_hash[:modal] = true unless aria_hash.key?(:modal) || aria_hash.key?("modal")

        # Set aria-labelledby if provided
        if @labelledby_id && !aria_hash.key?(:labelledby) && !aria_hash.key?("labelledby")
          aria_hash[:labelledby] = @labelledby_id
        end

        # Set aria-describedby if provided
        if @describedby_id && !aria_hash.key?(:describedby) && !aria_hash.key?("describedby")
          aria_hash[:describedby] = @describedby_id
        end

        dynamic_attrs[:aria] = aria_hash

        div(
          role: :dialog,
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "fixed left-[50%] top-[50%] z-50",
          "grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4",
          "border border-border bg-background p-6 shadow-lg",
          "transition-all duration-200",
          "sm:rounded-lg"
        ].join(" ")
      end
    end

    # Dialog header
    class DialogHeader < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "flex flex-col space-y-1.5 text-center sm:text-left"
      end
    end

    # Dialog footer
    class DialogFooter < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2"
      end
    end

    # Dialog title
    class DialogTitle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h2(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "text-lg font-semibold leading-none tracking-tight"
      end
    end

    # Dialog description
    class DialogDescription < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        p(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "text-sm text-muted-foreground"
      end
    end
  end
end
