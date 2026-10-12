# frozen_string_literal: true

require "test_helper"

class Views::DesignSystem::Parity::ShowTest < ActiveSupport::TestCase
  test "disables Turbo Drive on the body like the Turbo-less React harness" do
    html = ApplicationController.new.view_context.render(Views::DesignSystem::Parity::Show.new(html: "<p>x</p>"))

    assert_match(/<body[^>]*data-turbo="false"/, html)
  end
end
