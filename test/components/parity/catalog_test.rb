# frozen_string_literal: true

require "test_helper"

class Components::Parity::CatalogTest < ActiveSupport::TestCase
  Catalog = Components::Parity::Catalog

  test "one entry per scenario file whose V2 class exists, never the harness or primitives files" do
    names = Catalog.entries.map(&:component)

    assert_includes names, "button"
    assert_includes names, "navigation-menu"
    assert_empty names.grep(/\A_/)
    assert_equal names.sort, names
  end

  test "the preview is the first light default scenario and its tree is pruned of harness probes" do
    entry = Catalog.entries.find { |e| e.component == "popover" }

    assert_equal "default__closed", entry.scenario_id
    assert_operator entry.scenario_count, :>, 10
    probes = entry.tree["children"].filter_map { |c| c.dig("props", "data-testid") }

    assert_empty probes
    assert_equal 1, entry.tree["children"].size, "only the Popover remains"
  end

  test "prune only removes probe children and keeps the rest of the tree" do
    tree = { "c" => "_div", "children" => [ { "c" => "_div", "props" => { "data-testid" => "outside" } }, { "c" => "_div", "props" => { "data-testid" => "keep" } }, "text" ] }

    assert_equal [ { "c" => "_div", "props" => { "data-testid" => "keep" }, "children" => [] }, "text" ], Catalog.prune(tree)["children"]
  end

  test "a component without scenarios or a light scenario has no entry" do
    assert_nil Catalog.build("x", [])
    assert_nil Catalog.build("x", [ { "id" => "default", "dark" => true, "tree" => {} } ])
  end
end
