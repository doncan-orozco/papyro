module ActiveStorage
  module Sluggable
    extend ActiveSupport::Concern

    included do
      before_create :set_slug
    end

    def slug_url(**options)
      Rails.application.routes.url_helpers.action_text_markdown_upload_url(slug, **options)
    end

    private
      def set_slug
        self.slug ||= SecureRandom.alphanumeric(24)
      end
  end
end

ActiveSupport.on_load :active_storage_attachment do
  include ActiveStorage::Sluggable
end
