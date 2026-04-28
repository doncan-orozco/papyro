# frozen_string_literal: true

module Components
  module Admin
    class Navbar < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        header(class: merged_classes, **attrs_without_class) do
          div(class: "mx-auto flex h-14 max-w-6xl items-center justify-between px-4") do
            link_to studio_articles_path, class: "flex items-center", data: { turbo_frame: "_top" } do
              img(src: "/icon.svg", alt: t("studio.navbar.logo_alt"), class: "size-7")
              span(class: "text-lg font-semibold tracking-tight") { t("studio.navbar.title") }
            end

            div(class: "flex items-center gap-2") do
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
        "sticky top-0 z-40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60"
      end
    end
  end
end
