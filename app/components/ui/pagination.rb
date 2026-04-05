# frozen_string_literal: true

# Pagination - page number controls component
# Following shadcn/ui Radix patterns with semantic tokens
module Components
  module Ui
    # Pagination root container
    class Pagination < Components::Base
      def view_template(&block)
        nav(
          role: :navigation,
          aria: { label: "pagination" },
          class: merged_classes,
          **attrs_without_class,
        ) do
          yield self if block
        end
      end

      def content(**attrs, &block)
        render Content.new(**attrs), &block
      end

      def item(**attrs, &block)
        render Item.new(**attrs), &block
      end

      def link(**attrs, &block)
        render Link.new(**attrs), &block
      end

      def previous(**attrs, &block)
        render Previous.new(**attrs), &block
      end

      def next(**attrs, &block)
        render Next.new(**attrs), &block
      end

      def ellipsis(**attrs, &block)
        render Ellipsis.new(**attrs), &block
      end

      private

      def classes
        "mx-auto flex w-full justify-center"
      end
    end

    # Pagination Content wrapper
    class Pagination::Content < Components::Base
      def view_template(&block)
        ul(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex flex-row items-center gap-1"
      end
    end

    # Pagination Item - wrapper for individual pagination elements
    class Pagination::Item < Components::Base
      def view_template(&block)
        li(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Pagination Link - clickable page number
    class Pagination::Link < Components::Base
      def initialize(href: nil, active: false, size: :default, **attrs)
        @href = href
        @active = active
        @size = size
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add aria-current if active
        if @active
          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:current] = "page" unless aria_hash.key?(:current) || aria_hash.key?("current")
          dynamic_attrs[:aria] = aria_hash
        end

        if @href
          a(href: @href, class: merged_classes, **dynamic_attrs, &block)
        else
          span(class: merged_classes, **dynamic_attrs, &block)
        end
      end

      private

      def classes
        [
          base_classes,
          @active ? active_classes : inactive_classes,
          size_classes[@size]
        ].compact.join(" ")
      end

      def base_classes
        [
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium",
          "transition-colors",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "disabled:pointer-events-none disabled:opacity-50"
        ].join(" ")
      end

      def active_classes
        "border border-input bg-background hover:bg-accent hover:text-accent-foreground"
      end

      def inactive_classes
        "hover:bg-accent hover:text-accent-foreground"
      end

      def size_classes
        {
          default: "h-10 px-4 py-2",
          sm: "h-9 px-3",
          lg: "h-11 px-8",
          icon: "h-10 w-10"
        }
      end
    end

    # Pagination Previous - previous page button
    class Pagination::Previous < Components::Base
      def initialize(href: nil, **attrs)
        @href = href
        @attrs = attrs
      end

      def view_template(&block)
        render Components::Ui::PaginationLink.new(
          href: @href,
          aria: { label: "Go to previous page" },
          size: :default,
          **@attrs
        ) do
          # Chevron left icon
          svg(
            class: "h-4 w-4",
            xmlns: "http://www.w3.org/2000/svg",
            width: 24,
            height: 24,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: 2,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          ) do |s|
            s.path(d: "m15 18-6-6 6-6")
          end

          if block
            span { yield }
          else
            span { "Previous" }
          end
        end
      end
    end

    # Pagination Next - next page button
    class Pagination::Next < Components::Base
      def initialize(href: nil, **attrs)
        @href = href
        @attrs = attrs
      end

      def view_template(&block)
        render Components::Ui::PaginationLink.new(
          href: @href,
          aria: { label: "Go to next page" },
          size: :default,
          **@attrs
        ) do
          if block
            span { yield }
          else
            span { "Next" }
          end

          # Chevron right icon
          svg(
            class: "h-4 w-4",
            xmlns: "http://www.w3.org/2000/svg",
            width: 24,
            height: 24,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: 2,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          ) do |s|
            s.path(d: "m9 18 6-6-6-6")
          end
        end
      end
    end

    # Pagination Ellipsis - indicator for skipped pages
    class Pagination::Ellipsis < Components::Base
      def view_template
        span(
          aria: { hidden: true },
          class: merged_classes,
          **attrs_without_class
        ) do
          # More horizontal icon
          svg(
            class: "h-4 w-4",
            xmlns: "http://www.w3.org/2000/svg",
            width: 24,
            height: 24,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: 2,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          ) do |s|
            s.circle(cx: 12, cy: 12, r: 1)
            s.circle(cx: 19, cy: 12, r: 1)
            s.circle(cx: 5, cy: 12, r: 1)
          end
          span(class: "sr-only") { "More pages" }
        end
      end

      private

      def classes
        "flex h-9 w-9 items-center justify-center"
      end
    end

    PaginationContent = Pagination::Content
    PaginationItem = Pagination::Item
    PaginationLink = Pagination::Link
    PaginationPrevious = Pagination::Previous
    PaginationNext = Pagination::Next
    PaginationEllipsis = Pagination::Ellipsis
  end
end
