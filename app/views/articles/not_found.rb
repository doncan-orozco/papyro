# frozen_string_literal: true

module Views
  module Articles
    class NotFound < Components::Base
      def initialize(author: nil, **attrs)
        @author = author
        @attrs = attrs
      end

      def view_template
        view_context.content_for(:page_title, "404 - #{t("articles.not_found.title")}")

        noindex_tag = capture { meta(name: "robots", content: "noindex") }
        view_context.content_for(:head, noindex_tag)
        view_context.content_for(:suppress_seo_links, true)

        div(class: cn("max-w-2xl mx-auto mt-32 px-4 text-center", @attrs&.dig(:class)), **attrs_without_class) do
          div(class: "h-20 w-20 bg-muted/50 rounded-full flex items-center justify-center mx-auto mb-8") do
            render Components::Ui::Icon.new(:alert_triangle, class: "h-8 w-8 text-foreground/80")
          end

          h1(class: "text-3xl font-bold tracking-tight mb-4") { t("articles.not_found.title") }
          p(class: "text-foreground/75 text-lg mb-12") do
            t("articles.not_found.description")
          end

          div(class: "flex flex-col sm:flex-row items-center justify-center gap-4") do
            if author_link?
              render Components::Ui::Button.new(as: :a, href: author_path(author_username), size: :lg, class: "w-full sm:w-auto") do
                t("articles.not_found.more_from_author", author_name: author_name)
              end
            end
            render Components::Ui::Button.new(as: :a, href: root_path, variant: :outline, size: :lg, class: "w-full sm:w-auto hover:underline focus-visible:underline") do
              t("articles.not_found.discover")
            end
          end
        end
      end

      private

      def author_link?
        !!(defined?(author_username) && author_username.present?)
      end

      def author_username
        return unless defined?(author) && author
        author.respond_to?(:username) ? author.username : nil
      end

      def author_name
        return unless defined?(author) && author
        author.respond_to?(:name) ? author.name : nil
      end

      attr_reader :author
    end
  end
end
