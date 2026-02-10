class ArticlesController < ApplicationController
  allow_unauthenticated_access

  def featured
    render Views::Articles::Featured.new
  end

  def show
    @article = Article.find_by!(slug: params[:slug], status: :published)
    render Views::Articles::Show.new(@article)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Article not found"
  end
end
