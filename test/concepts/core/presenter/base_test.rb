require "test_helper"

class Core::Presenter::BaseTest < ActiveSupport::TestCase
  test "delegates wrapped object methods via SimpleDelegator" do
    article = articles(:draft_article)
    presenter = Core::Presenter::Base.new(article)

    assert_presenter_delegates(presenter, :id, :status, :original_locale)
  end
end
