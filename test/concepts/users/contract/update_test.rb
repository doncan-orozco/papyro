require "test_helper"

class Users::Contract::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "succeeds when params are empty" do
    result = Users::Contract::Update.new.call({})

    assert_predicate result, :success?
  end

  test "allows invalid email at contract layer" do
    result = Users::Contract::Update.new.call(email_address: "not-an-email")

    assert_predicate result, :success?
  end

  test "allows duplicate email at contract layer" do
    result = Users::Contract::Update.new.call(email_address: @other_user.email_address)

    assert_predicate result, :success?
  end

  test "fails for mismatched password confirmation" do
    result = Users::Contract::Update.new.call(
      password: "password123",
      password_confirmation: "different"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:password_confirmation)
  end
end
