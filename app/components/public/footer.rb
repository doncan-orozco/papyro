# frozen_string_literal: true

module Components
  module Public
    class Footer < Components::Base
      def view_template
        footer(class: "mt-10 border-t border-border bg-background px-4 py-6 sm:mt-12") do
          div(class: "mx-auto flex w-full max-w-6xl flex-col items-center justify-between gap-4 sm:flex-row") do
            p(class: "text-sm text-muted-foreground") do
              t("components.public.footer.copyright", year: Time.current.year)
            end

            nav(class: "flex items-center gap-6", aria: { label: t("components.public.footer.nav_label") }) do
              link_to t("components.public.footer.about"),
                about_path,
                class: "text-sm text-muted-foreground transition-colors hover:text-foreground",
                data: { turbo_frame: "_top", turbo_action: "advance" }
            end
          end
        end
      end
    end
  end
end
