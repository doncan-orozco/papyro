class UserPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    owner?
  end

  def edit?
    update?
  end

  private

  def owner?
    user.present? && record.id == user.id
  end
end
