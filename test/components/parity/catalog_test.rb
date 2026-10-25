# frozen_string_literal: true

require "test_helper"

class Components::Parity::CatalogTest < ActiveSupport::TestCase
  Catalog = Components::Parity::Catalog

  test "wraps every gem entry and adds the page anchor" do
    entry = Catalog.entries.find { |e| e.component == "button-group" }

    assert_equal Chadcn::Catalog.entries.size, Catalog.entries.size
    assert_equal "v2-button-group", entry.anchor
    assert_equal "Button group", entry.title
  end
end
