# frozen_string_literal: true

require "vips"

module Articles
  module Service
    # Generates a PNG Open Graph image for an article by rendering an SVG
    # template and converting it to PNG via ruby-vips.
    #
    # ruby-vips is already available as a transitive dependency of the
    # image_processing gem (v1.14+ depends on ruby-vips >= 2.0.17).
    class OgImageGenerator
      OG_IMAGE_WIDTH = 1200
      OG_IMAGE_HEIGHT = 630

      def initialize(article)
        @article = article
      end

      # Renders the SVG template, converts it to a PNG buffer via libvips,
      # and writes the result to a Tempfile.
      #
      # Returns a Tempfile (PNG) ready to be attached via Active Storage.
      def call
        svg_string = render_svg_template
        png_buffer = convert_svg_to_png(svg_string)
        write_to_tempfile(png_buffer)
      rescue Vips::Error => e
        Rails.logger.error("[OgImageGenerator] Vips conversion failed for article #{@article.id}: #{e.message}")
        raise
      end

      private

      def render_svg_template
        ApplicationController.render(
          template: "articles/og_image",
          formats: [ :svg ],
          locals: {
            article: @article,
            author_name: author_display_name,
            publish_date: formatted_publish_date
          }
        )
      end

      def convert_svg_to_png(svg_string)
        image = Vips::Image.new_from_buffer(svg_string, "")
        image.write_to_buffer(".png[compression=9]")
      end

      def write_to_tempfile(png_buffer)
        tempfile = Tempfile.new([ "og-image-#{@article.slug}", ".png" ])
        tempfile.binmode
        tempfile.write(png_buffer)
        tempfile.rewind
        tempfile
      end

      def author_display_name
        @article.user&.author_display_name.presence || "Papyro"
      end

      def formatted_publish_date
        date = @article.published_at || @article.created_at
        return "" unless date
        I18n.l(date.to_date, format: :long)
      end
    end
  end
end
