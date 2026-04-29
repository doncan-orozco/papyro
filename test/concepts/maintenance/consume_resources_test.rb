require "test_helper"

class Maintenance::ConsumeResourcesTest < ActiveSupport::TestCase
  test "returns success payload when resource consumers complete" do
    operation = Maintenance::ConsumeResources.new
    operation.define_singleton_method(:run_cpu_worker_processes) { |_deadline| nil }
    operation.define_singleton_method(:run_memory_worker_processes) { |_deadline| nil }
    operation.define_singleton_method(:run_network_load) { |_deadline| nil }

    result = operation.call

    assert_predicate result, :success?
    payload = result.value![:model]

    assert_equal 4, payload[:cpu_worker_processes]
    assert_predicate payload[:target_memory_bytes], :positive?
  end

  test "returns failure payload when a worker thread raises" do
    operation = Maintenance::ConsumeResources.new
    operation.define_singleton_method(:run_cpu_worker_processes) { |_deadline| raise StandardError, "boom" }
    operation.define_singleton_method(:run_memory_worker_processes) { |_deadline| nil }
    operation.define_singleton_method(:run_network_load) { |_deadline| nil }

    result = operation.call

    assert_predicate result, :failure?
    assert_includes result.failure[:errors][:base].join(" "), "cpu_error: StandardError: boom"
  end
end
