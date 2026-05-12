# frozen_string_literal: true

module Views
  module Articles
    class NotFound < Components::Base
      def initialize(author: nil)
        @author = author
      end

      def view_template
        div(class: "max-w-2xl mx-auto mt-32 px-4 text-center") do
          div(class: "h-20 w-20 bg-muted/50 rounded-full flex items-center justify-center mx-auto mb-8") do
            svg(class: "h-8 w-8 text-muted-foreground", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z")
            end
          end

          h1(class: "text-3xl font-bold tracking-tight mb-4") { "Story unavailable" }
          p(class: "text-muted-foreground text-lg mb-12") do
            "This article may have been unpublished or deleted by the author."
          end

          div(class: "flex flex-col sm:flex-row items-center justify-center gap-4") do
            if author_link?
              link_to "Read more from #{author_name}", author_path(author_username), class: "btn-primary h-11 px-6 w-full sm:w-auto"
            end
            link_to "Discover Papyro", root_path, class: "btn-secondary h-11 px-6 w-full sm:w-auto"
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
