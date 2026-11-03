class MarkdownRenderer
  # Raw HTML in an article body is untrusted: only these tags and attributes survive
  # rendering, and the lightbox wiring only in the shape MarkdownRenderer#image emits.
  class Scrubber < Rails::HTML::PermitScrubber
    TAGS = (Rails::HTML5::SafeListSanitizer.allowed_tags.to_a + %w[table thead tbody tfoot tr th td details summary figure figcaption]).freeze
    ATTRIBUTES = (Rails::HTML5::SafeListSanitizer.allowed_attributes.to_a + %w[id style aria-hidden colspan rowspan open data-action data-lightbox-url-value]).freeze
    LIGHTBOX_ACTION = "lightbox#open:prevent"
    LIGHTBOX_URL = %r{\A(?:/(?!/)|https?://)}i

    def initialize
      super
      self.tags = TAGS
      self.attributes = ATTRIBUTES
    end

    protected
      def scrub_attributes(node)
        scrub_lightbox_attributes(node)
        super
      end

    private
      def scrub_lightbox_attributes(node)
        lightbox_link = node.name == "a" && node["data-action"] == LIGHTBOX_ACTION

        node.remove_attribute("data-action") unless lightbox_link
        node.remove_attribute("data-lightbox-url-value") unless lightbox_link && node["data-lightbox-url-value"].to_s.match?(LIGHTBOX_URL)
      end
  end
end
