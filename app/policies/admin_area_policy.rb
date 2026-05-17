class AdminAreaPolicy < ApplicationPolicy
  def access?
    user&.admin?
  end
end
