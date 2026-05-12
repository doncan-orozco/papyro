# frozen_string_literal: true

class AuthorsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @profile = AuthorProfile.find_by!(username: params[:username])
    @author = @profile.user
    @pagy, @articles = pagy(
      Articles::PublishedQuery.call({}, scope: @author.articles),
      limit: 12
    )
    skip_authorization
    render Views::Authors::Show.new(author: @author, profile: @profile, articles: @articles, pagy: @pagy)
  end
end
