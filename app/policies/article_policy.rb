class ArticlePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.published? || owner?
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      return scope.where(status: :published) unless user

      scope.where(user: user)
    end
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
