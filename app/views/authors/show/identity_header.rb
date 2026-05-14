# frozen_string_literal: true

module Views
  module Authors
    class Show::IdentityHeader < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        div(class: "flex flex-col md:flex-row items-start gap-6 md:gap-8 mb-16") do
          div(
            class: "h-24 w-24 shrink-0 rounded-full border border-border bg-muted flex items-center justify-center text-3xl font-bold text-muted-foreground select-none",
            aria: { hidden: "true" }
          ) { @presenter.avatar_initial }

          div(class: "min-w-0 flex-1") do
            div(class: "flex flex-col md:flex-row md:items-start justify-between gap-4") do
              div(class: "space-y-1") do
                h1(class: "text-3xl font-extrabold tracking-tight") { @presenter.display_name }
                p(class: "text-sm text-muted-foreground") { "@#{@presenter.username}" }
              end

              if @presenter.owner?
                render Components::Ui::Button.new(
                  as: :a,
                  href: edit_settings_profile_path,
                  variant: :outline,
                  size: :sm,
                  class: "w-fit",
                  data: { turbo_frame: "_top" }
                ) { t("authors.show.edit_profile") }
              end
            end

            if @presenter.bio.present?
              p(class: "mt-4 text-base leading-relaxed max-w-2xl text-foreground/90") { @presenter.bio }
            end

            render Show::MetaAndSocialLinks.new(presenter: @presenter) if @presenter.any_meta_or_social?
          end
        end
      end
    end
  end
end
