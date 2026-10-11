# frozen_string_literal: true

require "test_helper"

class Components::V2::EmptyTest < ActiveSupport::TestCase
  def html(**opts, &block)
    Components::V2::Empty.new(**opts).call(&(block || proc { |_| "Body" }))
  end

  test "root renders slot and merges class" do
    out = html(class: "p-2", id: "e")

    assert_includes out, 'data-slot="empty"'
    assert_includes out, 'id="e"'
    assert_not_includes out.slice(/class="([^"]*)"/, 1).split, "p-6"
  end

  test "media variants" do
    default = Components::V2::Empty::Media.new(variant: :default).call { "x" }
    icon = Components::V2::Empty::Media.new(variant: "icon").call { "x" }

    assert_includes default, 'data-slot="empty-icon"'
    assert_includes default, 'data-variant="default"'
    assert_includes default, "bg-transparent"
    assert_includes icon, 'data-variant="icon"'
    assert_includes icon, "bg-muted"
    assert_equal Components::V2::Empty::Media.variants(variant: :icon), Components::V2::Empty::Media.variants(variant: "icon")
    assert_raises(ArgumentError) { Components::V2::Empty::Media.new(variant: :nope) }
  end

  test "helpers render the same HTML as the explicit classes" do
    helpers = html do |e|
      e.header { e.title { "T" } }
      e.media(variant: :icon) { "i" }
      e.description { "D" }
      e.content { "C" }
    end
    explicit = html do |e|
      e.render(Components::V2::Empty::Header.new) { e.render(Components::V2::Empty::Title.new) { "T" } }
      e.render(Components::V2::Empty::Media.new(variant: :icon)) { "i" }
      e.render(Components::V2::Empty::Description.new) { "D" }
      e.render(Components::V2::Empty::Content.new) { "C" }
    end

    assert_equal explicit, helpers
  end
end
