# frozen_string_literal: true

require "test_helper"

class Components::Parity::CatalogTest < ActiveSupport::TestCase
  Catalog = Components::Parity::Catalog

  test "one entry per ported component, sorted, never the harness or primitives files" do
    names = Catalog.entries.map(&:component)

    assert_includes names, "button"
    assert_includes names, "navigation-menu"
    assert_empty names.grep(/\A_/)
    assert_equal names.sort, names
  end

  test "the preview is the first light default scenario and its tree is free of harness probes" do
    entry = Catalog.entries.find { |e| e.component == "popover" }

    assert_equal "default__closed", entry.scenario_id
    assert_operator entry.scenario_count, :>, 10
    assert_empty entry.tree["children"].filter_map { |c| c.dig("props", "data-testid") }
    assert_equal 1, entry.tree["children"].size, "only the Popover remains"
  end

  test "an entry adds the page anchor to the gem's entry" do
    entry = Catalog.entries.find { |e| e.component == "button-group" }

    assert_equal "v2-button-group", entry.anchor
    assert_equal "Button group", entry.title
  end
end
