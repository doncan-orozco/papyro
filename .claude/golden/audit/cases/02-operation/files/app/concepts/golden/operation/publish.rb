module Golden
  module Operation
    class Publish < Core::Operation
      def call(article_id:)
        article = Article.find(article_id)
        authorize article, :publish?
        user = Current.user

        Article.transaction do
          article.update!(published_at: Time.current, publisher: user)
        end

        Success(article)
      end
    end
  end
end
