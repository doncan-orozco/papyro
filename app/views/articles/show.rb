# frozen_string_literal: true

module Views
  module Articles
    class Show < Views::Base
      def initialize(article)
        @article = article
      end

      def view_template
        article(class: "mx-auto max-w-4xl px-4 py-8") do
          header(class: "mb-8") do
            h1(class: "font-bold text-5xl mb-4") { @article.title }

            if @article.excerpt.present?
              p(class: "text-xl text-gray-600 mb-4") { @article.excerpt }
            end

            div(class: "flex items-center gap-4 text-sm text-gray-500") do
              if @article.published_at
                time(datetime: @article.published_at.iso8601) do
                  @article.published_at.strftime("%B %d, %Y")
                end
              end

              if @article.user
                span { "by #{@article.user.email_address}" }
              end
            end
          end

          div(class: "prose prose-lg max-w-none") do
            raw @article.content.to_s
          end
        end
      end
    end
  end
end
