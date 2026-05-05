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
                render Components::Ui::DropdownMenu.new(class: "relative") do |dropdown|
                  dropdown.trigger(class: "size-8 rounded-full bg-muted text-foreground text-sm font-semibold hover:bg-muted/80") do
                    span(aria: { hidden: "true" }) { avatar_initial }
                  end

                  dropdown.content(class: "w-48 mt-1") do
                    dropdown.item(href: user_path(Current.user), data: { turbo_frame: "_top" }) do
                      t("components.public.navbar.dropdown.my_profile")
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
                        turbo_confirm: t("studio.navbar.confirm_sign_out"),
                        turbo_frame: "_top"
                      }
                    ) { t("studio.navbar.sign_out") }
                  end
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

      def classes
        "sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur supports-[backdrop-filter]:bg-background/70"
      end
    end
  end
end
