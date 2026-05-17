# frozen_string_literal: true

module Views
  module Authors
    class Show < Views::Base
      def initialize(presenter:, articles:, pagy:)
        @presenter = presenter
        @articles = articles
        @pagy = pagy
      end

      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new
          main(class: "mx-auto w-full max-w-5xl space-y-10 px-4 py-10") do
            render Show::IdentityHeader.new(presenter: @presenter)
            render Show::ArticlesSection.new(presenter: @presenter, articles: @articles, pagy: @pagy)
          end
        end
      end
    end
  end
end
