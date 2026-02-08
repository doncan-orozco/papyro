class ArticlesController < ApplicationController
  allow_unauthenticated_access

  def featured
    render Views::Articles::Featured.new
  end
end
