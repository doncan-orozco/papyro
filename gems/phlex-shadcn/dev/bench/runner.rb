# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require "date" # phlex 2.4.1 references Date without requiring it; plain Ruby 4 does not preload it
require "json"
require "phlex/shadcn"
require_relative "scenarios"

module Bench
  # Measures the scenarios and compares allocations with the recorded baseline.
  module Runner
    BASELINE = File.expand_path("baseline.json", __dir__)
    ITERATIONS = 200
    WARMUP = 20
    # Allocations may exceed the baseline by this fraction before --check fails.
    DEFAULT_TOLERANCE = 0.02

    module_function

    def call(argv)
      results = measure
      baseline = File.exist?(BASELINE) ? JSON.parse(File.read(BASELINE)) : {}
      if argv.include?("--record")
        record(results, baseline)
      elsif argv.include?("--check")
        check(results, baseline, json: argv.include?("--json"))
      else
        report(results, baseline, json: argv.include?("--json"))
      end
    end

    # @return [Hash{String => Hash}] scenario => {"us" => Float, "allocations" => Integer} per render
    def measure
      Scenarios::ALL.transform_values do |build|
        WARMUP.times { build.call.call }
        GC.start
        GC.disable
        allocated = GC.stat(:total_allocated_objects)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ITERATIONS.times { build.call.call }
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        allocated = GC.stat(:total_allocated_objects) - allocated
        GC.enable
        { "us" => (elapsed * 1_000_000 / ITERATIONS).round(1), "allocations" => (allocated.to_f / ITERATIONS).round }
      end
    end

    def record(results, baseline)
      data = { "tolerance" => baseline.fetch("tolerance", DEFAULT_TOLERANCE), "ruby" => RUBY_VERSION,
               "allocations" => results.transform_values { |r| r["allocations"] } }
      File.write(BASELINE, "#{JSON.pretty_generate(data)}\n")
      puts "recorded #{BASELINE}"
      0
    end

    def report(results, baseline, json:)
      return puts(JSON.pretty_generate(results)).then { 0 } if json

      recorded = baseline.fetch("allocations", {})
      puts format("%-12s %12s %14s %12s", "scenario", "us/render", "allocs/render", "baseline")
      results.each do |name, r|
        puts format("%-12s %12.1f %14d %12s", name, r["us"], r["allocations"], recorded.fetch(name, "-"))
      end
      0
    end

    def check(results, baseline, json:)
      recorded = baseline.fetch("allocations", {})
      tolerance = baseline.fetch("tolerance", DEFAULT_TOLERANCE)
      failures = results.filter_map do |name, r|
        limit = recorded[name]
        next "#{name}: no baseline (run bin/bench --record)" unless limit
        next if r["allocations"] <= limit * (1 + tolerance)

        "#{name}: #{r["allocations"]} allocations per render, baseline #{limit} (+#{(tolerance * 100).round(1)}% allowed)"
      end
      json ? puts(JSON.pretty_generate(results)) : report(results, baseline, json: false)
      warn failures.join("\n") unless failures.empty?
      failures.empty? ? 0 : 1
    end
  end
end
