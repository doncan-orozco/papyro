# frozen_string_literal: true

class FeaturedArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    articles = Articles::PublishedQuery.call({}, scope: policy_scope(Article)).limit(4)
    authorize Article, :index?
    render Views::Articles::Featured.new(articles: articles)
  end
end
