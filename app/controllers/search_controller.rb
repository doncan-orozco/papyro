# frozen_string_literal: true

class SearchController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    skip_authorization
    query = params[:q].to_s.strip

    if query.present?
      @articles = Articles::Query::Search.call({ query: query }).limit(10)
      @authors = search_authors(query)
    else
      @articles = Article.none
      @authors = User.none
    end

    render Components::Public::SearchResults.new(
      query: query,
      articles: @articles,
      authors: @authors
    ), layout: false
  end

  private

  def search_authors(query)
    words = query.split(/\s+/)
    profile_scope = AuthorProfile.all

    words.each do |word|
      safe_word = ActiveRecord::Base.sanitize_sql_like(word)
      profile_scope = profile_scope.where(
        "author_profiles.display_name LIKE :q OR author_profiles.username LIKE :q",
        q: "%#{safe_word}%"
      )
    end

    User.includes(profile: { portrait_attachment: :blob })
        .joins(:profile)
        .where(role: :member)
        .merge(profile_scope)
        .limit(5)
        .distinct
  end
end
