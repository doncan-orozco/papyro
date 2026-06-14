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
            link_to root_path, class: "group inline-flex shrink-0 items-center gap-3", data: { turbo_frame: "_top", turbo_action: "advance" } do
              span(
                role: "img",
                aria: { label: "Papyro" },
                class: "size-7 shrink-0 bg-current text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 group-focus-visible:text-rose-600 dark:group-hover:text-rose-500 dark:group-focus-visible:text-rose-500 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
              )
              span(class: "hidden text-sm font-semibold tracking-[0.16em] text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 group-focus-visible:text-rose-600 dark:group-hover:text-rose-500 dark:group-focus-visible:text-rose-500 sm:inline") { "PAPYRO" }
            end

            render Components::Public::SearchForm.new(class: "min-w-0 flex-1")

            render Components::Shared::LanguageToggle.new
            render Components::Shared::ThemeToggle.new

            if Current.user.registered?
              render Components::Ui::Button.new(
                as: :a,
                href: studio_articles_href,
                variant: :outline,
                size: :sm,
                class: "h-10 rounded-full px-4 transition-colors duration-500 hover:border-rose-600 hover:text-rose-600 dark:hover:border-rose-500 dark:hover:text-rose-500",
                data: { turbo_frame: "_top", turbo_action: "advance" }
              ) { t("components.public.navbar.write") }

              render Components::Ui::DropdownMenu.new(class: "relative") do |dropdown|
                dropdown.trigger(
                  class: "size-10 rounded-full border border-border bg-muted/70 text-foreground text-xs font-bold uppercase tracking-[0.14em] hover:bg-muted/90 focus-visible:ring-2 focus-visible:ring-ring",
                  aria: { label: t("components.public.navbar.dropdown.settings") }
                ) do
                  span(aria: { hidden: "true" }) { avatar_initial }
                end

                dropdown.content(class: "w-48 mt-1") do
                  dropdown.item(href: author_path(Current.user.profile.username), data: { turbo_frame: "_top" }) do
                    t("components.public.navbar.dropdown.my_profile")
                  end
                  dropdown.item(href: studio_articles_href, data: { turbo_frame: "_top" }) do
                    t("components.public.navbar.dropdown.studio")
                  end
                  dropdown.item(href: edit_settings_profile_path, data: { turbo_frame: "_top" }) do
                    t("components.public.navbar.dropdown.settings")
                  end
                  dropdown.separator
                  dropdown.item(
                    href: session_path,
                    variant: :destructive,
                    data: {
                      turbo_method: :delete,
                      turbo_confirm: t("components.public.navbar.dropdown.confirm_sign_out"),
                      turbo_frame: "_top"
                    }
                  ) { t("components.public.navbar.dropdown.sign_out") }
                end
              end
            else
              div(class: "flex items-center gap-2") do
                link_to(
                  t("components.public.navbar.sign_in"),
                  new_session_path,
                  class: "px-2 py-1.5 text-sm font-medium text-foreground/80 transition-colors hover:text-foreground hover:underline focus-visible:underline focus-visible:ring-2 focus-visible:ring-ring",
                  data: { turbo_frame: "_top", turbo_action: "advance" }
                )

                render Components::Ui::Button.new(
                  as: :a,
                  href: sign_up_path,
                  variant: :default,
                  size: :sm,
                  data: { turbo_frame: "_top", turbo_action: "advance" }
                ) do
                  t("components.public.navbar.get_started")
                end
              end
            end
          end
        end
      end

      private

      def avatar_initial
        name = Current.user.profile&.display_name.presence || Current.user.email_address
        name.first.upcase
      end

      def studio_articles_href
        view_context.papyro_studio.articles_url(
          subdomain: "studio",
          locale: I18n.locale
        )
      end

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
