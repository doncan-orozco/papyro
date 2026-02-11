class ArticlesController < ApplicationController
  allow_unauthenticated_access

  def featured
    @articles = Articles::PublishedQuery.call(limit: 4)
    render Views::Articles::Featured.new(@articles)
  end

  def show
    @article = Article.find_by!(slug: params[:slug], status: :published)
    render Views::Articles::Show.new(@article)
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
