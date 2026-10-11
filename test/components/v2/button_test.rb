# frozen_string_literal: true

require "test_helper"

class Components::V2::ButtonTest < ActiveSupport::TestCase
  def html(**opts)
    Components::V2::Button.new(**opts).call { |_| "Go" }
  end

  test "renders defaults" do
    out = html

    assert_includes out, 'data-slot="button"'
    assert_includes out, 'data-variant="default"'
    assert_includes out, 'data-size="default"'
    assert_not_includes out, "type="
  end

  test "renders every variant and size, normalizing underscores" do
    Components::V2::Button::VARIANTS.each_key { |v| assert_includes html(variant: v), %(data-variant="#{v}") }
    Components::V2::Button::SIZES.each_key { |s| assert_includes html(size: s), %(data-size="#{s}") }
    assert_includes html(size: :icon_sm), 'data-size="icon-sm"'
  end

  test "class is merged last and attrs pass through" do
    out = html(class: "rounded-full", id: "x", disabled: true, data: { foo: "1" })

    assert_includes out, "rounded-full"
    assert_not_includes out, "rounded-md"
    assert_includes out, 'id="x"'
    assert_includes out, 'data-foo="1"'
    assert_includes out, "disabled"
  end

  test "unknown options raise" do
    assert_raises(ArgumentError) { html(variant: :nope) }
  end

  test "as_child tag" do
    out = html(as_child: :a, href: "/x")

    assert_match(/<a /, out)
    assert_includes out, 'href="/x"'
  end

  test "variants class method" do
    assert_includes Components::V2::Button.variants(variant: :outline, size: :sm, class: "x"), "border bg-background"
  end
end
