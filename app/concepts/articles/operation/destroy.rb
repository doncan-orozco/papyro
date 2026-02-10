# frozen_string_literal: true

module Articles
  module Operation
    class Destroy < Trailblazer::Operation
      step :find_article
      step :destroy_article

      def find_article(ctx, params:, **)
        article = ::Article.find_by(id: params[:id])
        if article
          ctx[:model] = article
          true
        else
          ctx[:errors] = { base: [I18n.t("errors.messages.article_not_found")] }
          false
        end
      end

      def destroy_article(ctx, model:, **)
        if model.destroy
          true
        else
          ctx[:errors] = model.errors.to_hash
          false
        end
      end
    end
  end
end
