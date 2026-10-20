# frozen_string_literal: true

require "stringio"
require_relative "engine_helper"

# `rake phlex_shadcn:doctor` inside the booted engine test application: exit status and output format.
class EngineTest::DoctorTask < Minitest::Test
  def app = EngineTest::Application

  def run_task(*)
    previous = Rake.application
    Rake.application = Rake::Application.new
    app.load_tasks
    out = StringIO.new
    original = $stdout
    $stdout = out
    status = begin
      Rake::Task["phlex_shadcn:doctor"].invoke(*)
      0
    rescue SystemExit => e
      e.status
    end
    [ status, out.string ]
  ensure
    $stdout = original
    Rake.application = previous
  end

  def test_the_task_is_defined_by_the_engine
    previous = Rake.application
    Rake.application = Rake::Application.new
    app.load_tasks

    assert Rake::Task.task_defined?("phlex_shadcn:doctor")
  ensure
    Rake.application = previous
  end

  def test_the_bare_application_fails_the_doctor_with_a_non_zero_exit
    status, out = run_task

    assert_equal 1, status
    assert_includes out, "[FAIL] source block"
    assert_includes out, "fix:"
  end

  def test_json_output
    status, out = run_task("json")
    json = JSON.parse(out)

    assert_equal 1, status
    refute json["ok"]
    assert_includes json["checks"].map { |check| check["name"] }, "tailwind"
  end

  def test_json_output_from_the_environment_variable
    ENV["JSON"] = "1"
    status, out = run_task

    assert_equal 1, status
    refute JSON.parse(out)["ok"]
  ensure
    ENV.delete("JSON")
  end
end
