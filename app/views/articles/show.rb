# frozen_string_literal: true

module Views
  module Articles
    class Show < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        # Use view_context.content_for to properly bridge with Rails ERB layout
        view_context.content_for(:page_title, @presenter.title)

        if @presenter.excerpt.present?
          view_context.content_for(:meta_description, @presenter.excerpt)
        end

        if @presenter.cover_image_attached?
          view_context.content_for(:og_image, view_context.url_for(@presenter.cover_image))
        end

        if @presenter.translation_fallback?
          # Use capture to convert Phlex HTML to string for content_for
          fallback_tag = capture { meta(name: "robots", content: "noindex,follow") }
          view_context.content_for(:head, fallback_tag)
        end

        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "relative overflow-hidden") do
            div(class: "pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.06),transparent_60%)]")

            div(class: "px-4 pb-14 sm:px-6 sm:pb-16") do
              div(class: "mx-auto w-full max-w-3xl") do
                render Show::TranslationFallbackBanner.new(original_locale: @presenter.original_locale) if @presenter.translation_fallback?
                render Show::Intro.new(presenter: @presenter)
                render Show::Byline.new(presenter: @presenter)
                render Show::Content.new(presenter: @presenter)
              end
            end
          end
          # Render JSON-LD in the body for SEO, Turbo-safe (idiomatic Phlex)
          if @presenter.respond_to?(:json_ld)
            script(id: "article-json-ld", type: "application/ld+json") do
              @presenter.json_ld.merge({ "@context": "https://schema.org" }).to_json.html_safe
            end
          end
          render Show::FooterNavigation.new(presenter: @presenter)
        end
      end
    end
  end
end
