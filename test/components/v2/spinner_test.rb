# frozen_string_literal: true

require "test_helper"

class Components::V2::SpinnerTest < ActiveSupport::TestCase
  test "renders lucide svg with status role and no aria-hidden" do
    html = Components::V2::Spinner.new.call

    assert_includes html, "<svg"
    assert_includes html, 'role="status"'
    assert_includes html, 'aria-label="Loading"'
    assert_includes html, "lucide-loader-circle"
    assert_includes html, "size-4 animate-spin"
    refute_includes html, "aria-hidden"
    refute_includes html, "data-slot"
  end

  test "caller class wins and attrs pass through" do
    html = Components::V2::Spinner.new(class: "size-8", id: "s", aria: { label: "Saving" }, color: "red").call

    assert_includes html, "size-8"
    refute_includes html, "size-4"
    assert_includes html, 'id="s"'
    assert_includes html, 'aria-label="Saving"'
    assert_includes html, 'stroke="red"'
  end
end
