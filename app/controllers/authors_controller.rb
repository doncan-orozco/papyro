# frozen_string_literal: true

class AuthorsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @profile = AuthorProfile.friendly.find(params[:username])
    skip_authorization

    canonical_path = author_path(@profile.username)
    return redirect_to(canonical_path, status: :moved_permanently) if request.path != canonical_path

    @author = @profile.user
    @pagy, @articles = pagy(
      Articles::Query::Published.call({}, scope: @author.articles),
      limit: 12
    )
    presenter = ::Authors::Presenter::Default.new(@profile, author: @author, current_user: Current.user)
    render Views::Authors::Show.new(presenter: presenter, articles: @articles, pagy: @pagy)
  end
end
