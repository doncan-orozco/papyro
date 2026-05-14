# frozen_string_literal: true

class AuthorsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @profile = AuthorProfile.find_by!(username: params[:username])
    @author = @profile.user
    @pagy, @articles = pagy(
      Articles::Query::Published.call({}, scope: @author.articles),
      limit: 12
    )
    presenter = ::Authors::Presenter::Default.new(@profile, author: @author, current_user: Current.user)
    skip_authorization
    render Views::Authors::Show.new(presenter: presenter, articles: @articles, pagy: @pagy)
  end
end
