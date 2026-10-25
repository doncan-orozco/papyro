# frozen_string_literal: true

module Components
  module Public
    # Account dropdown of the public navbar (profile, Studio, settings, sign out).
    class Navbar::AccountMenu < Components::Base
      TOP_FRAME = { turbo_frame: "_top" }.freeze
      private_constant :TOP_FRAME

      def initialize(user:, studio_href:)
        @user = user
        @studio_href = studio_href
      end

      def view_template
        render Chadcn::DropdownMenu.new do |dropdown|
          dropdown.trigger(
            class: "size-10 rounded-full border border-border bg-muted/70 text-foreground text-xs font-bold uppercase tracking-[0.14em] hover:bg-muted/90 focus-visible:ring-2 focus-visible:ring-ring",
            aria: { label: t("components.public.navbar.dropdown.settings") }
          ) do
            span(aria: { hidden: "true" }) { avatar_initial }
          end

          dropdown.content(class: "w-48 mt-1") do
            dropdown.item(as_child: :a, href: author_path(@user.profile.username), data: TOP_FRAME) do
              t("components.public.navbar.dropdown.my_profile")
            end
            dropdown.item(as_child: :a, href: @studio_href, data: TOP_FRAME) do
              t("components.public.navbar.dropdown.studio")
            end
            dropdown.item(as_child: :a, href: edit_settings_profile_path, data: TOP_FRAME) do
              t("components.public.navbar.dropdown.settings")
            end
            dropdown.separator
            dropdown.item(
              as_child: :a,
              href: session_path,
              variant: "destructive",
              data: {
                turbo_method: :delete,
                turbo_confirm: t("components.public.navbar.dropdown.confirm_sign_out"),
                **TOP_FRAME
              }
            ) { t("components.public.navbar.dropdown.sign_out") }
          end
        end
      end

      private

      def avatar_initial
        name = @user.profile&.display_name.presence || @user.email_address
        name.first.upcase
      end
    end
  end
end
