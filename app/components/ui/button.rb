module Components
  module Ui
    class Button < Components::Base
      # shadcn/ui Radix button component - pixel-perfect match
      # Updated: 2026-02-16 - Uses semantic tokens with Tailwind v4
      def initialize(variant: :default, size: :default, **attrs)
        @variant = variant
        @size = size
        @attrs = attrs
      end

      def view_template(&block)
        button(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        [
          base_classes,
          variant_classes[@variant],
          size_classes[@size]
        ].compact.join(" ")
      end

      def base_classes
        [
          # Layout
          "inline-flex items-center justify-center whitespace-nowrap",
          # SVG handling
          "[&_svg:not([class*='size-'])]:size-4",
          "[&_svg]:pointer-events-none",
          "shrink-0 [&_svg]:shrink-0",
          # Focus and interaction states
          "transition-all",
          "focus-visible:ring-3",
          "aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
          "aria-invalid:border-destructive dark:aria-invalid:border-destructive/50",
          # Disabled state
          "disabled:pointer-events-none disabled:opacity-50",
          # Styling
          "rounded-lg border border-transparent bg-clip-padding text-sm font-medium outline-none group/button select-none"
        ].join(" ")
      end

      def variant_classes
        {
          default: "bg-primary text-primary-foreground hover:bg-primary/90 focus-visible:ring-primary/20 dark:focus-visible:ring-primary/40",
          destructive: "bg-destructive/10 hover:bg-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 text-destructive focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 focus-visible:border-destructive/40",
          outline: "border-border bg-background text-foreground hover:bg-muted hover:text-foreground dark:border-input dark:hover:bg-muted focus-visible:ring-ring/20",
          secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80 dark:bg-secondary dark:hover:bg-secondary/80 focus-visible:ring-secondary/20",
          ghost: "text-foreground hover:bg-muted dark:hover:bg-muted focus-visible:ring-muted/20",
          link: "text-foreground underline-offset-4 hover:underline dark:text-foreground"
        }
      end

      def size_classes
        {
          default: "h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
          xs: "h-6 gap-1 px-2 text-xs has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5",
          sm: "h-8 gap-1.5 px-3 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
          lg: "h-10 gap-2 px-4 has-data-[icon=inline-end]:pr-3 has-data-[icon=inline-start]:pl-3",
          icon: "h-8 w-8",
          "icon-xs": "h-6 w-6",
          "icon-sm": "h-8 w-8",
          "icon-lg": "h-10 w-10"
        }
      end
    end
  end
end
