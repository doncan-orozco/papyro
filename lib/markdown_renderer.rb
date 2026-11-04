require "rouge/plugins/redcarpet"
require "uri"

class MarkdownRenderer < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet

  # Every caller that outputs HTML goes through build or render, so the output is always sanitized.
  def self.build
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)
    Sanitized.new(Redcarpet::Markdown.new(renderer, ActionText::Markdown::DEFAULT_MARKDOWN_EXTENSIONS))
  end

  def self.render(markdown)
    build.render(markdown)
  end

  class Sanitized
    def initialize(markdown)
      @markdown = markdown
    end

    def render(text)
      Rails::HTML5::SafeListSanitizer.new.sanitize(@markdown.render(text), scrubber: Scrubber.new).html_safe
    end
  end

  def initialize(*args)
    super
    @id_counts = Hash.new(0)
  end

  def header(text, header_level)
    unique_id(text).then do |id|
      "<h#{header_level} id='#{id}'>#{text} <a href='##{id}' class='heading__link' aria-hidden='true'>#</a></h#{header_level}>"
    end
  end

  def image(url, title, alt_text)
    normalized_url = normalize_upload_url(url)
    src = ERB::Util.html_escape(normalized_url)
    lightbox_url = ERB::Util.html_escape("#{normalized_url}?disposition=attachment")

    %(<a href="#{src}" data-action="lightbox#open:prevent" data-lightbox-url-value="#{lightbox_url}"><img src="#{src}" alt="#{ERB::Util.html_escape(alt_text)}" title="#{ERB::Util.html_escape(title)}"></a>)
  end

  private
    def normalize_upload_url(url)
      return url if url.blank?

      uri = URI.parse(url)
      return url unless uri.path.start_with?("/u/")

      request_path = uri.path.to_s
      request_path += "?#{uri.query}" if uri.query.present?

      request_path
    rescue URI::InvalidURIError
      url
    end

    def unique_id(text)
      text.parameterize.then do |base_id|
        @id_counts[base_id] += 1
        @id_counts[base_id] > 1 ? "#{base_id}-#{@id_counts[base_id]}" : base_id
      end
    end
end
