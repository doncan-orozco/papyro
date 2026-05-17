# frozen_string_literal: true

module Admin
  module Presenter
    class Default < Core::Presenter::Base
      def self.wrap(collection)
        collection.map { |item| new(item) }
      end

      def initialize(article)
        super(article)
      end

      def status_variant
        case status
        when "draft" then :secondary
        when "published" then :default
        when "archived" then :outline
        else :secondary
        end
      end

      def status_label
        I18n.t("admin.articles.index.statuses.#{status}")
      end

      def published_label
        return I18n.t("admin.articles.index.not_published") unless published_at
        I18n.l(published_at, format: :short)
      end

      def has_excerpt?
        excerpt.present?
      end

      def excerpt_text
        excerpt
      end
    end
  end
end
