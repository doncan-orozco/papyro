ENV["RAILS_ENV"] ||= "test"

require_relative "supports/simplecov"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    parallelize_setup do |_worker|
      SimpleCov.command_name "Worker::#{Process.pid}" if defined?(SimpleCov)
    end

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      I18n.locale = I18n.default_locale
    end

    # Add more helper methods to be used by all tests here...
  end
end
