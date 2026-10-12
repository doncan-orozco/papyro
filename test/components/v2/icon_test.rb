# frozen_string_literal: true

require "test_helper"

class Components::V2::IconTest < ActiveSupport::TestCase
  test "renders like lucide-react without a size class" do
    html = Components::V2::Icon.new(:check).call

    assert_includes html, 'class="lucide lucide-check"'
    assert_includes html, 'width="24"'
    assert_includes html, 'height="24"'
    assert_not_includes html, "size-"
  end

  test "keeps a caller size class" do
    html = Components::V2::Icon.new("chevron-right", class: "size-3 text-primary").call

    assert_includes html, "lucide lucide-chevron-right"
    assert_includes html, "size-3"
  end

  test "unknown name raises" do
    assert_raises(ArgumentError) { Components::V2::Icon.new(:nope_not_an_icon).call }
  end

  test "accepts the harness names, lucide aliases and React export names" do
    %w[more-horizontal MoreHorizontal ellipsis loader-circle Loader2Icon trash-2 circle-help house arrow-up].each do |name|
      assert_includes Components::V2::Icon.new(name).call, "<svg", name
    end
    assert_includes Components::V2::Icon.new("more-horizontal").call, "lucide-ellipsis"
    assert_includes Components::V2::Icon.new("link-2").call, 'class="lucide lucide-link2 lucide-link-2"'
  end
end
