module Golden
  module Operation
    class Publish < Core::Operation
      def call(model:, user:)
        publishable = step ensure_unpublished(model)
        published = step persist_publication(publishable, user)

        { model: published }
      end

      private

      def ensure_unpublished(model)
        return Success(model) unless model.published?

        fail_with_code!(model, :already_published, message: I18n.t("errors.messages.article_already_published"))
      end

      def persist_publication(model, user)
        return Success(model) if model.update(published_at: Time.current, publisher: user)

        fail_with_model!(model)
      end
    end
  end
end
