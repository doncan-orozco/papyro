# frozen_string_literal: true

module Articles
  module Operation
    class Publish < Trailblazer::Operation
      step :find_article
      step :validate_publishable
      step :publish_article

      def find_article(ctx, params:, **)
        article = ::Article.find_by(id: params[:id])
        if article
          ctx[:model] = article
          true
        else
          ctx[:errors] = { base: [ I18n.t("errors.messages.article_not_found") ] }
          false
        end
      end

      def validate_publishable(ctx, model:, params:, **)
        action = params[:action] || "publish"

        if action == "publish"
          # Can't publish if already published
          if model.status_published?
            ctx[:errors] = { base: [ I18n.t("errors.messages.article_already_published") ] }
            return false
          end
          # Must have title and content to publish
          if model.title.blank? || model.content.body.blank?
            ctx[:errors] = { base: [ I18n.t("errors.messages.article_incomplete_for_publish") ] }
            return false
          end
        elsif action == "unpublish"
          # Can't unpublish if not published
          unless model.status_published?
            ctx[:errors] = { base: [ I18n.t("errors.messages.article_not_published") ] }
            return false
          end
        end

        ctx[:action] = action
        true
      end

      def publish_article(ctx, model:, action:, **)
        if action == "publish"
          model.update(status: :published, published_at: Time.current)
        else
          model.update(status: :draft, published_at: nil)
        end
      end
    end
  end
end
