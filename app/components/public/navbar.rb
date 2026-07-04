# frozen_string_literal: true

module Components
  module Public
    class Navbar < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        header(class: merged_classes, **attrs_without_class) do
          div(class: "mx-auto flex w-full max-w-6xl items-center gap-4 px-4 py-3") do
            # Logo (shrink-0)
            div(class: "flex shrink-0 items-center") do
              link_to root_path, class: "group inline-flex shrink-0 items-center gap-3", data: { turbo_frame: "_top", turbo_action: "advance" } do
                span(
                  role: "img",
                  aria: { label: "Papyro" },
                  class: "size-7 shrink-0 bg-current text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 group-focus-visible:text-rose-600 dark:group-hover:text-rose-500 dark:group-focus-visible:text-rose-500 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
                )
                span(class: "hidden text-sm font-semibold tracking-[0.16em] text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 group-focus-visible:text-rose-600 dark:group-hover:text-rose-500 dark:group-focus-visible:text-rose-500 sm:inline") { "PAPYRO" }
              end
            end

            # Mobile Search Dialog
            render Components::Ui::Dialog.new(data: { action: "turbo:before-cache@document->ui--dialog#closeImmediately" }, class: "md:hidden flex-1") do |search_dialog|
              search_dialog.trigger(class: "block") do
                render Components::Ui::Button.new(
                  variant: :outline,
                  class: "w-full h-9 rounded-full justify-start bg-muted/40 text-muted-foreground border-border/50 hover:bg-muted/60",
                  aria: { label: t("components.public.navbar.mobile.search_label") }
                ) do
                  render Components::Ui::Icon.new(:search, class: "mr-2 size-4")
                  span(class: "text-sm font-normal") { t("components.public.navbar.mobile.search_label") }
                end
              end

              search_dialog.content(
                close_button: false,
                class: "fixed top-0 left-0 translate-y-0 translate-x-0 w-full max-w-none rounded-none border-b border-x-0 border-t-0 bg-background px-4 py-3 shadow-none data-[state=open]:!animate-in data-[state=closed]:!animate-out data-[state=closed]:!fade-out-0 data-[state=open]:!fade-in-0 data-[state=closed]:!slide-out-to-left data-[state=open]:!slide-in-from-left data-[state=open]:!slide-in-from-top-0 data-[state=open]:!zoom-in-0 data-[state=closed]:!zoom-out-0 data-[state=open]:!duration-200 data-[state=closed]:!duration-200"
              ) do
                h2(class: "sr-only") { t("components.public.navbar.mobile.search_label") }
                render Components::Public::SearchForm.new(frame_id: "mobile_search_results")
              end
            end

            # CENTER GROUP - Desktop SearchForm (SECOND in DOM)
            div(class: "hidden md:block flex-1 max-w-2xl") do
              render Components::Public::SearchForm.new
            end

            # RIGHT GROUP (THIRD in DOM)
            div(class: "flex shrink-0 items-center justify-end gap-3 ml-auto") do
              if Current.user.registered?
                div(class: "hidden md:flex items-center gap-1") do
                  render Components::Shared::LanguageToggle.new
                  render Components::Shared::ThemeToggle.new
                end

                render Components::Ui::Button.new(
                  as: :a,
                  href: studio_articles_href,
                  variant: :outline,
                  size: :sm,
                  class: "hidden md:inline-flex h-10 rounded-full px-4 transition-colors duration-500 hover:border-rose-600 hover:text-rose-600 dark:hover:border-rose-500 dark:hover:text-rose-500",
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

                render Components::Ui::Sheet.new(data: { action: "turbo:before-cache@document->ui--dialog#closeImmediately" }) do |mobile_sheet|
                  mobile_sheet.trigger(class: "md:hidden") do
                    render Components::Ui::Button.new(
                      variant: :ghost,
                      size: :icon,
                      aria: { label: t("components.public.navbar.mobile.menu_label") }
                    ) do
                      render Components::Ui::Icon.new(:menu, class: "size-4")
                    end
                  end

                  mobile_sheet.content(side: :right, class: "w-72") do
                    mobile_sheet.header do
                      mobile_sheet.title(class: "text-left text-xs font-semibold tracking-wider text-muted-foreground uppercase") do
                        t("components.public.navbar.mobile.menu_label")
                      end
                    end

                    div(class: "mt-6 flex flex-col gap-6") do
                      div(class: "flex flex-col gap-2") do
                        span(class: "text-xs font-semibold tracking-wider text-muted-foreground uppercase px-2 mb-1") do
                          t("design_system.theme.toggle_label")
                        end

                        div(data: { controller: "ui--theme" }) do
                          render Components::Ui::Button.new(
                            variant: :ghost,
                            class: "w-full justify-start gap-3",
                            data: { action: "click->ui--theme#setLight" }
                          ) do
                            render Components::Ui::Icon.new(:sun, class: "size-4 text-muted-foreground")
                            span { t("design_system.theme.light") }
                          end
                          render Components::Ui::Button.new(
                            variant: :ghost,
                            class: "w-full justify-start gap-3",
                            data: { action: "click->ui--theme#setDark" }
                          ) do
                            render Components::Ui::Icon.new(:moon, class: "size-4 text-muted-foreground")
                            span { t("design_system.theme.dark") }
                          end
                          render Components::Ui::Button.new(
                            variant: :ghost,
                            class: "w-full justify-start gap-3",
                            data: { action: "click->ui--theme#setSystem" }
                          ) do
                            render Components::Ui::Icon.new(:monitor, class: "size-4 text-muted-foreground")
                            span { t("design_system.theme.system") }
                          end
                        end
                      end

                      render Components::Ui::Separator.new

                      div(class: "flex flex-col gap-2") do
                        span(class: "text-xs font-semibold tracking-wider text-muted-foreground uppercase px-2 mb-1") do
                          t("components.shared.language_toggle.menu_label")
                        end

                        link_to root_path(locale: :en), class: "inline-flex h-9 items-center justify-start gap-3 whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground w-full" do
                          render Components::Ui::Icon.new(:globe, class: "size-4 text-muted-foreground")
                          span { t("components.shared.language_toggle.english") }
                        end

                        link_to root_path(locale: :es), class: "inline-flex h-9 items-center justify-start gap-3 whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground w-full" do
                          render Components::Ui::Icon.new(:globe, class: "size-4 text-muted-foreground")
                          span { t("components.shared.language_toggle.spanish") }
                        end
                      end
                    end
                  end
                end
              else
                div(class: "hidden md:flex items-center gap-1") do
                  render Components::Shared::LanguageToggle.new
                  render Components::Shared::ThemeToggle.new
                end

                div(class: "hidden md:flex items-center gap-2") do
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

                render Components::Ui::Sheet.new(data: { action: "turbo:before-cache@document->ui--dialog#closeImmediately" }) do |mobile_sheet|
                  mobile_sheet.trigger(class: "md:hidden") do
                    render Components::Ui::Button.new(
                      variant: :ghost,
                      size: :icon,
                      aria: { label: t("components.public.navbar.mobile.menu_label") }
                    ) do
                      render Components::Ui::Icon.new(:menu, class: "size-4")
                    end
                  end

                  mobile_sheet.content(side: :right, class: "w-72") do
                    mobile_sheet.header do
                      mobile_sheet.title(class: "text-left text-xs font-semibold tracking-wider text-muted-foreground uppercase") do
                        t("components.public.navbar.mobile.menu_label")
                      end
                    end

                    div(class: "mt-6 flex flex-col gap-3") do
                      # Primary CTA first
                      render Components::Ui::Button.new(
                        as: :a,
                        href: sign_up_path,
                        variant: :default,
                        class: "w-full",
                        data: { turbo_frame: "_top", turbo_action: "advance" }
                      ) do
                        t("components.public.navbar.get_started")
                      end

                      # Secondary CTA, centered ghost button
                      render Components::Ui::Button.new(
                        as: :a,
                        href: new_session_path,
                        variant: :ghost,
                        class: "w-full justify-center text-muted-foreground hover:text-foreground",
                        data: { turbo_frame: "_top", turbo_action: "advance" }
                      ) do
                        t("components.public.navbar.sign_in")
                      end

                      render Components::Ui::Separator.new

                      div(class: "flex flex-col gap-2") do
                        span(class: "text-xs font-semibold tracking-wider text-muted-foreground uppercase px-2 mb-1") do
                          t("design_system.theme.toggle_label")
                        end

                        div(data: { controller: "ui--theme" }) do
                          render Components::Ui::Button.new(
                            variant: :ghost,
                            class: "w-full justify-start gap-3",
                            data: { action: "click->ui--theme#setLight" }
                          ) do
                            render Components::Ui::Icon.new(:sun, class: "size-4 text-muted-foreground")
                            span { t("design_system.theme.light") }
                          end
                          render Components::Ui::Button.new(
                            variant: :ghost,
                            class: "w-full justify-start gap-3",
                            data: { action: "click->ui--theme#setDark" }
                          ) do
                            render Components::Ui::Icon.new(:moon, class: "size-4 text-muted-foreground")
                            span { t("design_system.theme.dark") }
                          end
                          render Components::Ui::Button.new(
                            variant: :ghost,
                            class: "w-full justify-start gap-3",
                            data: { action: "click->ui--theme#setSystem" }
                          ) do
                            render Components::Ui::Icon.new(:monitor, class: "size-4 text-muted-foreground")
                            span { t("design_system.theme.system") }
                          end
                        end
                      end

                      render Components::Ui::Separator.new

                      div(class: "flex flex-col gap-2") do
                        span(class: "text-xs font-semibold tracking-wider text-muted-foreground uppercase px-2 mb-1") do
                          t("components.shared.language_toggle.menu_label")
                        end

                        link_to root_path(locale: :en), class: "inline-flex h-9 items-center justify-start gap-3 whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground w-full" do
                          render Components::Ui::Icon.new(:globe, class: "size-4 text-muted-foreground")
                          span { t("components.shared.language_toggle.english") }
                        end

                        link_to root_path(locale: :es), class: "inline-flex h-9 items-center justify-start gap-3 whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground w-full" do
                          render Components::Ui::Icon.new(:globe, class: "size-4 text-muted-foreground")
                          span { t("components.shared.language_toggle.spanish") }
                        end
                      end
                    end
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

      def studio_articles_href
        view_context.papyro_studio.articles_url(
          subdomain: "studio",
          locale: I18n.locale
        )
      end

      def merged_classes
        base_classes = "sticky top-0 z-50 border-b border-border bg-background"
        class_option = @attrs[:class]
        class_option ? "#{base_classes} #{class_option}" : base_classes
      end

      def attrs_without_class
        @attrs.except(:class)
      end
    end
  end
end
