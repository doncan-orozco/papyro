# frozen_string_literal: true

module Users
  module Query
    class Active < Core::Query::Application
      base_scope { User.all }

      pipeline :filter_active_users

      private

      def filter_active_users(current_scope)
        current_scope.where(suspended_at: nil)
      end
    end
  end
end
