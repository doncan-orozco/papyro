require "test_helper"

class AdminAreaPolicyTest < ActiveSupport::TestCase
  def policy(user)
    AdminAreaPolicy.new(user, :admin_area)
  end

  test "admin user can access admin area" do
    assert_predicate policy(users(:admin)), :access?
  end

  test "regular user cannot access admin area" do
    refute_predicate policy(users(:one)), :access?
  end

  test "unauthenticated visitor cannot access admin area" do
    refute_predicate policy(nil), :access?
  end
end
