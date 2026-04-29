require "test_helper"

class Maintenance::ConsumeResourcesJobTest < ActiveJob::TestCase
  SuccessResult = Struct.new(:payload) do
    def success?
      true
    end

    def failure
      {}
    end
  end

  FailureResult = Struct.new(:payload) do
    def success?
      false
    end

    def failure
      payload
    end
  end

  test "completes without raising when operation succeeds" do
    fake_operation = Struct.new(:result) do
      def call
        result
      end
    end.new(SuccessResult.new({ model: { ok: true } }))

    Maintenance::ConsumeResources.define_singleton_method(:new) { fake_operation }
    begin
      assert_nothing_raised do
        Maintenance::ConsumeResourcesJob.new.perform
      end
    ensure
      Maintenance::ConsumeResources.singleton_class.send(:remove_method, :new)
    end
  end

  test "raises ConsumeResourcesFailed when operation fails" do
    fake_operation = Struct.new(:result) do
      def call
        result
      end
    end.new(FailureResult.new({ errors: { base: [ "cpu unavailable" ] } }))

    Maintenance::ConsumeResources.define_singleton_method(:new) { fake_operation }
    begin
      error = assert_raises(Maintenance::ConsumeResourcesJob::ConsumeResourcesFailed) do
        Maintenance::ConsumeResourcesJob.new.perform
      end

      assert_includes error.message, "cpu unavailable"
    ensure
      Maintenance::ConsumeResources.singleton_class.send(:remove_method, :new)
    end
  end
end
