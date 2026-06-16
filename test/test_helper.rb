ENV["RAILS_ENV"] ||= "test"

require_relative "supports/simplecov"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/article_publication_test_helper"
require_relative "test_helpers/papyro_studio_route_test_helper"
require_relative "test_helpers/presenter_test_helper"
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
    set_fixture_class article_translations: Article::Translation
    set_fixture_class author_profile_translations: AuthorProfile::Translation
    include ArticlePublicationTestHelper
    include PresenterTestHelper

    setup do
      I18n.locale = I18n.default_locale
      Bullet.start_request if Bullet.enable?
    end

    teardown do
      Bullet.perform_out_of_channel_notifications if Bullet.enable? && Bullet.notification?
      Bullet.end_request if Bullet.enable?
    end

    # Add more helper methods to be used by all tests here...
  end
end
