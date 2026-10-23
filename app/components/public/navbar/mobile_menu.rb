# frozen_string_literal: true

module Components
  module Public
    # Right-hand sheet of the public navbar (guest CTAs, theme and language preferences) shown below md.
    class Navbar::MobileMenu < Components::Base
      TOP_LEVEL_NAVIGATION = { turbo_frame: "_top", turbo_action: "advance" }.freeze
      SECTION_LABEL_CLASSES = "text-xs font-semibold tracking-wider text-muted-foreground uppercase px-2 mb-1"
      LANGUAGES = {
        en: "components.shared.language_toggle.english",
        es: "components.shared.language_toggle.spanish"
      }.freeze
      private_constant :TOP_LEVEL_NAVIGATION, :SECTION_LABEL_CLASSES, :LANGUAGES

      def initialize(guest:)
        @guest = guest
      end

      def view_template
        render Chadcn::Sheet.new do |sheet|
          sheet.trigger(
            as_child: Chadcn::Button.new(variant: "ghost", size: "icon", class: "md:hidden"),
            aria: { label: t("components.public.navbar.mobile.menu_label") }
          ) do
            render Components::Shared::Icon.new(:menu, class: "size-4")
          end

          sheet.content(side: "right", class: "w-72", close_label: t("design_system.overlays.dialog.close")) do
            sheet.header do
              sheet.title(class: "text-left text-xs font-semibold tracking-wider text-muted-foreground uppercase") do
                t("components.public.navbar.mobile.menu_label")
              end
            end

            div(class: cn("mt-6 flex flex-col", @guest ? "gap-3" : "gap-6")) do
              if @guest
                guest_links
                render Chadcn::Separator.new
              end
              theme_choices
              render Chadcn::Separator.new
              language_links
            end
          end
        end
      end

      private

      def guest_links
        render Chadcn::Button.new(as_child: :a, href: sign_up_path, class: "w-full", data: TOP_LEVEL_NAVIGATION) do
          t("components.public.navbar.get_started")
        end

        render Chadcn::Button.new(
          as_child: :a,
          href: new_session_path,
          variant: "ghost",
          class: "w-full justify-center text-muted-foreground hover:text-foreground",
          data: TOP_LEVEL_NAVIGATION
        ) do
          t("components.public.navbar.sign_in")
        end
      end

      # The sheet content is portaled into <body>, so its buttons carry their own chadcn--theme controller.
      def theme_choices
        div(class: "flex flex-col gap-2") do
          span(class: SECTION_LABEL_CLASSES) { t("design_system.theme.toggle_label") }

          div(data: Components::Shared::ThemeToggle::CONTROLLER_DATA) do
            Components::Shared::ThemeToggle::CHOICES.each do |choice|
              render Chadcn::Button.new(
                variant: "ghost",
                class: "w-full justify-start gap-3",
                data: { action: choice.stimulus_action }
              ) do
                render Components::Shared::Icon.new(choice.icon, class: "size-4 text-muted-foreground")
                span { t(choice.label_key) }
              end
            end
          end
        end
      end

      def language_links
        div(class: "flex flex-col gap-2") do
          span(class: SECTION_LABEL_CLASSES) { t("components.shared.language_toggle.menu_label") }

          LANGUAGES.each do |locale, label_key|
            render Chadcn::Button.new(as_child: :a, href: root_path(locale: locale), variant: "ghost", class: "w-full justify-start gap-3") do
              render Components::Shared::Icon.new(:globe, class: "size-4 text-muted-foreground")
              span { t(label_key) }
            end
          end
        end
      end
    end
  end
end
