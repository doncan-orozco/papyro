class ArticlePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.published? || owner?
  end

  def create?
    registered_user?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      Articles::Query::Published.call({}, scope: scope)
    end
  end

  private

  def owner?
    registered_user? && record.user_id == user.id
  end

  def registered_user?
    user&.registered?
  end
end
