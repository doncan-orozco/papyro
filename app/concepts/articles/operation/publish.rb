# frozen_string_literal: true

module Articles
  module Operation
    class Publish < Trailblazer::Operation
      step :validate_publishable
      step :publish_article

      # No find_article step - model is pre-authorized by controller

      def validate_publishable(ctx, model:, params:, **)
        action = params[:action] || "publish"

        # Validate action is allowed
        unless [ "publish", "unpublish" ].include?(action)
          ctx[:errors] = { base: [ I18n.t("errors.messages.invalid_action") ] }
          return false
        end

        if action == "publish"
          # Can't publish if already published
          if model.status_published?
            ctx[:errors] = { base: [ I18n.t("errors.messages.article_already_published") ] }
            return false
          end
          # Must have title to publish
          if model.title.blank?
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
        success = if action == "publish"
          model.update(status: :published, published_at: Time.current)
        else
          model.update(status: :draft, published_at: nil)
        end

        return true if success

        ctx[:errors] = (ctx[:errors] || {}).merge(model.errors.to_hash)
        false
      end
    end
  end
end
