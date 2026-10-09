class GoldenArticlesController < ApplicationController
  def publish
    @article = Article.find(params[:id])

    if @article.trashed?
      redirect_to articles_path, alert: "Cannot publish a trashed article"
      return
    end

    @article.update!(status: :published)
    render html: view_context.tag.div(@article.title)
  end
end
