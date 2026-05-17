require "test_helper"

class Core::OperationTest < ActiveSupport::TestCase
  class DummyModel
    include ActiveModel::Model

    attr_accessor :title
  end

  class DummyOperation < Core::Operation
    def expose_inject_errors(model, errors_hash)
      inject_errors!(model, errors_hash)
    end

    def expose_fail_with_code(model, code, message: nil)
      fail_with_code!(model, code, message: message)
    end

    def expose_fail_with_model(model)
      fail_with_model!(model)
    end
  end

  test "inject_errors adds all provided errors" do
    model = DummyModel.new

    DummyOperation.new.expose_inject_errors(model, {
      title: [ "cannot be blank" ],
      base: [ "invalid state" ]
    })

    assert_includes model.errors[:title], "cannot be blank"
    assert_includes model.errors[:base], "invalid state"
  end

  test "fail_with_code returns standardized failure payload" do
    model = DummyModel.new
    model.errors.add(:base, "already published")

    result = DummyOperation.new.expose_fail_with_code(model, :already_published)

    assert_predicate result, :failure?
    assert_equal :already_published, result.failure[:code]
    assert_equal model, result.failure[:model]
    assert_equal "already published", result.failure[:message]
  end

  test "fail_with_model returns standardized failure payload" do
    model = DummyModel.new
    model.errors.add(:title, "invalid")

    result = DummyOperation.new.expose_fail_with_model(model)

    assert_predicate result, :failure?
    assert_equal model, result.failure[:model]
    assert_includes result.failure[:errors][:title], "invalid"
  end
end
