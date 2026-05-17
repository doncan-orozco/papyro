require "test_helper"

class GuestUserTest < ActiveSupport::TestCase
  setup do
    @guest = GuestUser.new
  end

  test "id returns nil" do
    assert_nil @guest.id
  end

  test "email_address returns nil" do
    assert_nil @guest.email_address
  end

  test "guest? returns true" do
    assert_predicate @guest, :guest?
  end

  test "registered? returns false" do
    assert_not @guest.registered?
  end

  test "admin? returns false" do
    assert_not @guest.admin?
  end

  test "member? returns false" do
    assert_not @guest.member?
  end
end
