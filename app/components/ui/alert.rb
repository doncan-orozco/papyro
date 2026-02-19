# frozen_string_literal: true

# Alert component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    # Alert container
    class Alert < Components::Base
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :alert,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          base_classes,
          variant_classes[@variant]
        ].compact.join(" ")
      end

      def base_classes
        [
          "relative w-full",
          "rounded-lg border",
          "px-4 py-3",
          "text-sm",
          "[&>svg~*]:pl-7 [&>svg+div]:translate-y-[-3px]",
          "[&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg]:text-foreground"
        ].join(" ")
      end

      def variant_classes
        {
          default: "bg-background text-foreground border-border",
          destructive: "border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive"
        }
      end
    end

    # Alert title
    class AlertTitle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h5(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "mb-1 font-medium leading-none tracking-tight"
      end
    end

    # Alert description
    class AlertDescription < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm [&_p]:leading-relaxed"
      end
    end
  end
end
