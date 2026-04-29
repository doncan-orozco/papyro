#=> test/supports/simplecov.rb
# frozen_string_literal: true

require "fileutils"
require "simplecov"

class SilentHtmlFormatter
  def format(result)
    with_silenced_stdout do
      SimpleCov::Formatter::HTMLFormatter.new.format(result)
    end
  end

  private

  def with_silenced_stdout
    original_stdout = $stdout
    silent_stdout = File.open(File::NULL, "w")
    $stdout = silent_stdout
    yield
  ensure
    $stdout = original_stdout
    silent_stdout.close if silent_stdout && !silent_stdout.closed?
  end
end

test_prepare_task = defined?(Rake) &&
  Rake.respond_to?(:application) &&
  Rake.application.respond_to?(:top_level_tasks) &&
  Rake.application.top_level_tasks.any? { |task| task == "test:prepare" }

unless test_prepare_task
  SimpleCov.minimum_coverage 80
  SimpleCov.merge_timeout 3600
  SimpleCov.command_name "Minitest"

  SimpleCov.start(:rails) do
    # Ignore files without functional code
    add_filter do |source_file|
      source = source_file.src
      ignored = source.reduce(0) do |ignored, line|
        case line.strip
        when /^$/, /^#/, /^class/, /^module/, /^end/
          ignored += 1
        end
        ignored
      end
      (source.count - ignored) <= 0 # When true, source_file is ignored
    end

    add_filter "vendor"
    add_filter "preview"
    add_filter "test"
    add_filter "spec"

    add_group "Policies", "app/policies"
    add_group "Concepts", "app/concepts"
    add_group "Components", "app/components"
    add_group "Views", "app/views"
    add_group "Queries", "app/queries"


    at_exit do
      result = SimpleCov.result

      if SimpleCov.command_name == "Minitest"
        SilentHtmlFormatter.new.format(result)
      end
    end
  end
end
