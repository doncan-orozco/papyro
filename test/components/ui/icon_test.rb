require "test_helper"

class Components::Ui::IconTest < ActiveSupport::TestCase
  test "renders svg element with default lucide icon" do
    html = ApplicationController.render(inline: "<%= render Components::Ui::Icon.new(:home) %>")

    assert_match /<svg/, html

    assert_match /<path/, html
  end

  test "passes size and class attributes through to svg" do
    html = ApplicationController.render(inline: "<%= render Components::Ui::Icon.new(:home, size: 16, class: 'my-icon') %>")

    assert_match /width="16"/, html

    assert_match /height="16"/, html
    assert_match /class=".*my-icon/, html
  end
end
