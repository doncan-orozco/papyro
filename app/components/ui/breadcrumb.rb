# frozen_string_literal: true

# Breadcrumb - navigation hierarchy indicator
module Components
  module Ui
    # Main breadcrumb container
    class Breadcrumb < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        nav(aria: { label: "breadcrumb" }, class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      def list(**attrs, &block)
        render List.new(**attrs, &block)
      end

      def item(**attrs, &block)
        render Item.new(**attrs, &block)
      end

      def link(href: nil, **attrs, &block)
        render Link.new(href: href, **attrs, &block)
      end

      def page(**attrs, &block)
        render Page.new(**attrs, &block)
      end

      def separator(**attrs, &block)
        render Separator.new(**attrs, &block)
      end

      def ellipsis(**attrs)
        render Ellipsis.new(**attrs)
      end

      private

      def classes
        ""
      end
      # Breadcrumb list wrapper
      class List < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          ol(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "flex flex-wrap items-center gap-1.5 break-words text-sm text-muted-foreground sm:gap-2.5"
        end
      end

      # Individual breadcrumb item
      class Item < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          li(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "inline-flex items-center gap-1.5"
        end
      end

      # Breadcrumb link
      class Link < Components::Base
        def initialize(href: nil, **attrs)
          @href = href
          @attrs = attrs
        end

        def view_template(&block)
          if @href
            a(href: @href, class: merged_classes, **attrs_without_class, &block)
          else
            span(class: merged_classes, **attrs_without_class, &block)
          end
        end

        private

        def classes
          "transition-colors hover:text-foreground"
        end
      end

      # Current breadcrumb page (no link)
      class Page < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          span(
            role: :link,
            aria: { current: "page" },
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        end

        private

        def classes
          "font-normal text-foreground"
        end
      end

      # Breadcrumb separator
      class Separator < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          li(
            role: :presentation,
            aria: { hidden: true },
            class: merged_classes,
            **attrs_without_class
          ) do
            if block
              yield
            else
              # Default separator
              svg(
                class: "size-3.5",
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

        private

        def classes
          "[&>svg]:size-3.5"
        end
      end

      # Breadcrumb ellipsis for collapsed items
      class Ellipsis < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template
          span(
            role: :presentation,
            aria: { hidden: true },
            class: merged_classes,
            **attrs_without_class
          ) do
            svg(
              class: "size-4",
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
          end
        end

        private

        def classes
          "flex h-9 w-9 items-center justify-center"
        end
      end
    end

    # Aliases to match with shadcn/ui naming conventions
    BreadcrumbList = Breadcrumb::List
    BreadcrumbItem = Breadcrumb::Item
    BreadcrumbLink = Breadcrumb::Link
    BreadcrumbPage = Breadcrumb::Page
    BreadcrumbSeparator = Breadcrumb::Separator
    BreadcrumbEllipsis = Breadcrumb::Ellipsis
  end
end
