# frozen_string_literal: true

module Studio
  # Authorization for Studio::ArticlesController — the creator's own workspace.
  #
  # Rules here are intentionally different from the public ArticlePolicy:
  # - Visibility is always scoped to the current user's own articles (not publication status).
  # - "Can create?" means "is authenticated?", not "is the article published?".
  # - Future Studio-only rules (e.g., draft-only editing, co-author checks) stay isolated here.
  class ArticlePolicy < ApplicationPolicy
    # new + create: any authenticated user may create articles in their own studio.
    def new?
      user.present?
    end

    def create?
      user.present?
    end

    # edit + update: only the owner may modify their own article.
    def edit?
      owner?
    end

    def update?
      owner?
    end

    # destroy: only the owner may delete their own article.
    def destroy?
      owner?
    end

    def restore?
      owner?
    end

    def purge?
      owner?
    end

    class Scope < Scope
      # Studio scope: always the current user's own articles regardless of status.
      def resolve
        scope.where(user: user)
      end
    end

    private

    def owner?
      user.present? && record.user_id == user.id
    end
  end
end
