# frozen_string_literal: true

module Views
  module Settings
    class Layout < Views::Base
      def initialize(active:)
        @active = active
      end

      def view_template(&block)
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          div(class: "mx-auto w-full max-w-4xl px-4 py-10") do
            div(class: "flex flex-col gap-8 md:flex-row md:gap-12") do
              aside(class: "w-full shrink-0 md:w-48") do
                nav(class: "flex flex-row gap-1 md:flex-col") do
                  sidebar_link(t("users.settings.profile.title"), edit_settings_profile_path, :profile)
                  sidebar_link(t("users.settings.security.title"), edit_settings_security_path, :security)
                end
              end

              main(class: "min-w-0 flex-1") do
                yield
              end
            end
          end
        end
      end

      private

      def sidebar_link(label, href, section)
        active = @active == section
        link_to(
          label,
          href,
          class: cn(
            "block rounded-md px-3 py-2 text-sm font-medium transition-colors",
            active ? "bg-muted text-foreground ring-1 ring-border font-semibold" : "text-foreground/80 hover:bg-muted hover:text-foreground hover:underline focus-visible:underline"
          )
        )
      end
    end
  end
end
