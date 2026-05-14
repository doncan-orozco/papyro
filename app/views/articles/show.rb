# frozen_string_literal: true

module Views
  module Articles
    class Show < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        div(class: "article-reader min-h-screen bg-background text-foreground", data: { controller: "fullscreen" }) do
          render Show::Header.new(back_path: articles_path)
          main(class: "px-4 pb-14 sm:px-6 sm:pb-16") do
            div(class: "mx-auto w-full max-w-3xl") do
              render Show::TranslationFallbackBanner.new if @presenter.translation_fallback?
              render Show::Intro.new(presenter: @presenter)
              render Show::Byline.new(presenter: @presenter)
              render Show::CoverImage.new(presenter: @presenter)
              render Show::Content.new(presenter: @presenter)
            end
          end
          render Show::FooterNavigation.new(presenter: @presenter)
        end
      end
    end
  end
end
