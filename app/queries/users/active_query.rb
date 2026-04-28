# frozen_string_literal: true

module Users
  class ActiveQuery < ApplicationQuery
    base_scope { User.all }

    pipeline :filter_suspended

    private

    def filter_suspended(current_scope)
      current_scope.where(suspended_at: nil)
    end
  end
end
