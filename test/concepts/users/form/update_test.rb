require "test_helper"

class Users::Form::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "validates update params and syncs normalized email" do
    form = Users::Form::Update.new(@user)

    assert form.validate(id: @user.id, email_address: "  NEW@EXAMPLE.COM ")
    form.sync

    assert_equal "new@example.com", @user.email_address
  end

  test "fails for duplicate email" do
    form = Users::Form::Update.new(@user)

    refute form.validate(id: @user.id, email_address: users(:two).email_address)
    assert_predicate form.errors[:email_address], :any?
  end

  test "sync assigns password when present" do
    form = Users::Form::Update.new(@user)

    assert form.validate(
      id: @user.id,
      password: "new-password",
      password_confirmation: "new-password"
    )
    form.sync

    assert @user.authenticate("new-password")
  end
end
