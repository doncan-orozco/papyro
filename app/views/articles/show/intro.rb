# frozen_string_literal: true

module Views
  module Articles
    class Show::Intro < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        section(class: "pb-8 pt-12 sm:pb-10 sm:pt-16") do
          link_to root_path,
            class: "mb-10 inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-foreground/80 transition-colors hover:text-foreground hover:underline focus-visible:underline",
            data: { turbo_frame: "_top" } do
            render Components::Ui::Icon.new(:arrow_left, class: "h-3.5 w-3.5")
            plain t("articles.show.back_to_list")
          end

          h1(class: "font-serif text-4xl font-semibold tracking-tight text-foreground sm:text-5xl") { @presenter.title }

          return unless @presenter.excerpt.present?

          p(class: "mt-6 text-lg leading-relaxed text-foreground/75") { @presenter.excerpt }
        end
      end
    end
  end
end
