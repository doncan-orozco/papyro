require "rouge/plugins/redcarpet"
require "uri"

class MarkdownRenderer < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet

  def self.build
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)
    Redcarpet::Markdown.new(renderer, ActionText::Markdown::DEFAULT_MARKDOWN_EXTENSIONS)
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
    %(<a href="#{normalized_url}" data-action="lightbox#open:prevent" data-lightbox-url-value="#{normalized_url}?disposition=attachment"><img src="#{normalized_url}" alt="#{alt_text}" title="#{title}"></a>)
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
