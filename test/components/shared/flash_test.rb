require "test_helper"

class Components::Shared::FlashTest < ActiveSupport::TestCase
  test "renders bottom-right toast container and notice message" do
    html = ApplicationController.render(
      inline: "<%= render Components::Shared::Flash.new(flash: { notice: 'Saved successfully' }) %>"
    )

    assert_match(/fixed/, html)
    assert_match(/bottom-4/, html)
    assert_match(/controller=\"toast\"/, html)
    assert_match(/Saved successfully/, html)
    assert_match(/Success/, html)
  end

  test "renders destructive variant for alert" do
    html = ApplicationController.render(
      inline: "<%= render Components::Shared::Flash.new(flash: { alert: 'Something failed' }) %>"
    )

    assert_match(/destructive/, html)
    assert_match(/Something failed/, html)
    assert_match(/Error/, html)
  end
end
