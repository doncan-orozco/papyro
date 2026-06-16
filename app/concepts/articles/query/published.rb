# frozen_string_literal: true

module Articles
  module Query
    class Published < Core::Query::Application
      base_scope { Article.all }

      pipeline :include_translations,
               :filter_by_locale,
               :filter_by_publication_status,
               :filter_by_global_overrides,
               :apply_ordering

      private

      def filter_by_locale(current_scope)
        locale = filters[:locale] || I18n.locale.to_s

        current_scope.joins(:translations)
                     .where(translations: { locale: locale })
      end

      def filter_by_publication_status(current_scope)
        current_scope.where(translations: { status: Article::Translation.statuses[:published] })
                     .where.not(articles: { published_at: nil })
      end

      def filter_by_global_overrides(current_scope)
        current_scope.where(articles: { deleted_at: nil, archived_at: nil })
      end

      def include_translations(current_scope)
        current_scope.preload(:translations).includes({user: :profile}, :markdown_body, cover_image_attachment: :blob)
      end

      def apply_ordering(current_scope)
        current_scope.order(articles: { published_at: :desc })
                     .distinct
      end
    end
  end
end
