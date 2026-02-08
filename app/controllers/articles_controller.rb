class ArticlesController < ApplicationController
  def featured
    render Views::Articles::Featured.new
  end
end
