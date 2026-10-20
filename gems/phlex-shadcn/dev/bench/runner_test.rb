# frozen_string_literal: true

# Run with: cd gems/phlex-shadcn && env -u BUNDLE_GEMFILE bundle exec ruby dev/bench/runner_test.rb
require "minitest/autorun"
require_relative "runner"

class BenchRunnerTest < Minitest::Test
  BASELINE = { "tolerance" => 0.02, "allocations" => { "button" => 100 } }.freeze

  def test_within_tolerance_passes
    assert_empty Bench::Runner.regressions({ "button" => { "allocations" => 102 } }, BASELINE)
  end

  def test_over_tolerance_fails
    assert_match(/button: 103 allocations/, Bench::Runner.regressions({ "button" => { "allocations" => 103 } }, BASELINE).first)
  end

  def test_missing_baseline_fails_loud
    assert_match(/card: no baseline/, Bench::Runner.regressions({ "card" => { "allocations" => 1 } }, BASELINE).first)
  end

  def test_unknown_flag_exits_two
    status = nil
    capture_io { status = Bench::Runner.call(["--chek"]) }

    assert_equal 2, status
  end

  def test_reference_renders_the_same_html_as_button
    scenarios = Bench::Scenarios::ALL

    assert_equal scenarios["button"].call.call, scenarios["reference"].call.call
  end
end
