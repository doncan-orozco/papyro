# frozen_string_literal: true

module Users
  class ActiveQuery
    def self.call(scope = User.all)
      scope.where(suspended_at: nil)
    end
  end
end
