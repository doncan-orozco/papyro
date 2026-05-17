# frozen_string_literal: true

module Views
  module Articles
    class Show::Content < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        article(class: "pb-12") do
          div(class: "article-prose max-w-none text-foreground/90 dark:text-foreground/95") do
            raw @presenter.content_html
          end
        end
      end
    end
  end
end
