require "test_helper"

module Users
  class ActiveTest < ActiveSupport::TestCase
    test "returns only unsuspended users" do
      active_user = users(:admin)
      suspended_user = users(:one)
      suspended_user.update!(suspended_at: Time.current)

      result = Query::Active.call

      assert_includes result, active_user
      assert_not_includes result, suspended_user
    end
  end
end
