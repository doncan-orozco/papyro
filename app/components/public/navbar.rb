# frozen_string_literal: true

module Components
  module Public
    class Navbar < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        header(class: merged_classes, **attrs_without_class) do
          div(class: "mx-auto flex w-full max-w-6xl items-center gap-3 px-4 py-3") do
            link_to root_path, class: "inline-flex shrink-0 items-center gap-3", data: { turbo_frame: "_top", turbo_action: "advance" } do
              span(
                role: "img",
                aria: { label: "Papyro" },
                class: "size-7 shrink-0 bg-current text-foreground/70 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
              )
              span(class: "hidden text-sm font-semibold tracking-[0.16em] text-foreground/70 sm:inline") { "PAPYRO" }
            end

            render Components::Ui::Tooltip.new(class: "min-w-0 flex-1") do |tooltip|
              tooltip.trigger(class: "w-full") do
                div(class: "flex min-w-0 items-center gap-3 rounded-full border border-border bg-card/80 px-4 py-2 text-sm text-muted-foreground shadow-sm opacity-50 cursor-not-allowed") do
                  render Components::Ui::Icon.new(:search, class: "h-4 w-4 shrink-0")
                  span(class: "min-w-0 truncate") { t("articles.index.search_placeholder") }
                  span(class: "ml-auto rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-foreground") do
                    t("articles.index.search_soon")
                  end
                end
              end
              tooltip.content { t("articles.index.search_soon") }
            end

            render Components::Shared::ThemeToggle.new

            render Components::Ui::Button.new(
              as: :a,
              href: new_session_path,
              variant: :outline,
              size: :sm,
              data: { turbo_frame: "_top", turbo_action: "advance" }
            ) do
              t("pages.home.index.header.sign_in")
            end
          end
        end
      end

      private

      def merged_classes
        base_classes = "sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur supports-[backdrop-filter]:bg-background/70"
        class_option = @attrs[:class]
        class_option ? "#{base_classes} #{class_option}" : base_classes
      end

      def attrs_without_class
        @attrs.except(:class)
      end
    end
  end
end
