# frozen_string_literal: true

module Components
  module Public
    class Navbar < Components::Base
      TOP_LEVEL_NAVIGATION = { turbo_frame: "_top", turbo_action: "advance" }.freeze
      private_constant :TOP_LEVEL_NAVIGATION

      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        header(class: merged_classes, **attrs_without_class) do
          div(class: "mx-auto flex w-full max-w-6xl items-center gap-4 px-4 py-3") do
            logo
            mobile_search
            desktop_search

            div(class: "flex shrink-0 items-center justify-end gap-3 ml-auto") do
              desktop_preferences
              Current.user.registered? ? member_actions : guest_actions
            end
          end
        end
      end

      private

      def logo
        div(class: "flex shrink-0 items-center") do
          link_to root_path, class: "group inline-flex shrink-0 items-center gap-3", data: TOP_LEVEL_NAVIGATION do
            span(
              role: "img",
              aria: { label: "Papyro" },
              class: "size-7 shrink-0 bg-current text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 group-focus-visible:text-rose-600 dark:group-hover:text-rose-500 dark:group-focus-visible:text-rose-500 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
            )
            span(class: "hidden text-sm font-semibold tracking-[0.16em] text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 group-focus-visible:text-rose-600 dark:group-hover:text-rose-500 dark:group-focus-visible:text-rose-500 sm:inline") { "PAPYRO" }
          end
        end
      end

      def mobile_search
        search_label = t("components.public.navbar.mobile.search_label")

        div(class: "md:hidden flex-1") do
          render Chadcn::Sheet.new do |search_sheet|
            search_sheet.trigger(
              as_child: Chadcn::Button.new(
                variant: "outline",
                class: "w-full h-9 rounded-full justify-start bg-muted/40 text-muted-foreground border-border/50 hover:bg-muted/60"
              ),
              aria: { label: search_label }
            ) do
              render Components::Shared::Icon.new(:search, class: "mr-2 size-4")
              span(class: "text-sm font-normal") { search_label }
            end

            search_sheet.content(side: "top", close_label: t("design_system.overlays.dialog.close")) do
              search_sheet.title(class: "sr-only") { search_label }
              div(class: "px-4 py-3 pr-12") do
                render Components::Public::SearchForm.new(frame_id: "mobile_search_results")
              end
            end
          end
        end
      end

      def desktop_search
        div(class: "hidden md:block flex-1 max-w-2xl") do
          render Components::Public::SearchForm.new
        end
      end

      def desktop_preferences
        div(class: "hidden md:flex items-center gap-1") do
          render Components::Shared::LanguageToggle.new
          render Components::Shared::ThemeToggle.new
        end
      end

      def member_actions
        write_button
        render Navbar::AccountMenu.new(user: Current.user, studio_href: studio_articles_href)
        render Navbar::MobileMenu.new(guest: false)
      end

      def guest_actions
        guest_desktop_links
        render Navbar::MobileMenu.new(guest: true)
      end

      def write_button
        render Chadcn::Button.new(
          as_child: :a,
          href: studio_articles_href,
          variant: "outline",
          size: "sm",
          class: "hidden md:inline-flex h-10 rounded-full px-4 transition-colors duration-500 hover:border-rose-600 hover:text-rose-600 dark:hover:border-rose-500 dark:hover:text-rose-500",
          data: TOP_LEVEL_NAVIGATION
        ) { t("components.public.navbar.write") }
      end

      def guest_desktop_links
        div(class: "hidden md:flex items-center gap-2") do
          link_to(
            t("components.public.navbar.sign_in"),
            new_session_path,
            class: "px-2 py-1.5 text-sm font-medium text-foreground/80 transition-colors hover:text-foreground hover:underline focus-visible:underline focus-visible:ring-2 focus-visible:ring-ring",
            data: TOP_LEVEL_NAVIGATION
          )

          render Chadcn::Button.new(as_child: :a, href: sign_up_path, size: "sm", data: TOP_LEVEL_NAVIGATION) do
            t("components.public.navbar.get_started")
          end
        end
      end

      def studio_articles_href
        @studio_articles_href ||= view_context.papyro_studio.articles_url(
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
