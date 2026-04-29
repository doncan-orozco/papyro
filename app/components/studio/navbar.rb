# frozen_string_literal: true

module Components
  module Studio
    class Navbar < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        header(class: merged_classes, **attrs_without_class) do
          div(class: "mx-auto flex w-full max-w-6xl items-center gap-3 px-4 py-3") do
            link_to studio_articles_path,
              class: "inline-flex shrink-0 items-center gap-3",
              data: { turbo_frame: "_top", turbo_action: "advance" } do
              span(
                role: "img",
                aria: { label: "Papyro" },
                class: "size-7 shrink-0 bg-current text-foreground/70 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
              )
              span(class: "hidden text-sm font-semibold tracking-[0.16em] text-foreground/70 sm:inline") { "PAPYRO" }
            end

            nav(class: "hidden items-center gap-2 md:flex", aria: { label: t("studio.navbar.navigation_label") }) do
              render Components::Ui::Button.new(
                as: :a,
                href: studio_articles_path,
                variant: :ghost,
                size: :sm,
                data: { turbo_frame: "_top", turbo_action: "advance" }
              ) { t("studio.navbar.articles") }

              render Components::Ui::Button.new(
                as: :a,
                href: new_studio_article_path,
                size: :sm,
                data: { turbo_frame: "_top", turbo_action: "advance" }
              ) { t("studio.navbar.new_article") }
            end

            div(class: "ml-auto flex items-center gap-2") do
              render Components::Ui::Button.new(
                as: :a,
                href: root_path,
                variant: :outline,
                size: :sm,
                data: { turbo_frame: "_top", turbo_action: "advance" }
              ) { t("studio.navbar.view_site") }

              render Components::Shared::LanguageToggle.new
              render Components::Shared::ThemeToggle.new

              if Current.user
                link_to t("studio.navbar.sign_out"),
                  session_path,
                  class: "text-sm text-muted-foreground transition-colors hover:text-foreground",
                  data: {
                    turbo_method: :delete,
                    turbo_confirm: t("studio.navbar.confirm_sign_out"),
                    turbo_frame: "_top"
                  }
              end
            end
          end
        end
      end

      private

      def classes
        "sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur supports-[backdrop-filter]:bg-background/70"
      end
    end
  end
end
