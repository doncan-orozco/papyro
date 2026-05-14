# frozen_string_literal: true

module Views
  module Articles
    class Show::Intro < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        section(class: "pt-10 sm:pt-14") do
          h1(class: "text-3xl font-bold tracking-tight text-foreground sm:text-4xl md:text-5xl") { @presenter.title }
          return unless @presenter.excerpt.present?

          p(class: "mt-4 text-base leading-relaxed text-muted-foreground sm:text-lg") { @presenter.excerpt }
        end
      end
    end
  end
end
