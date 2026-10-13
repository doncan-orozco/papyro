# frozen_string_literal: true

require "phlex/test_case"

using Phlex::Shadcn::Support::Refinements

# Refinements are invisible to respond_to?/send, so the refined predicates are called directly (no assert_predicate), and the
# custom failure message of `assert Support.blank_value?(value), value.inspect` is intended.
# rubocop:disable Minitest/AssertPredicate, Minitest/AssertWithExpectedArgument

class Phlex::Shadcn::SupportTest < Phlex::Shadcn::TestCase
  Support = Phlex::Shadcn::Support

  test "blank values are nil, false, empty or whitespace strings and empty collections" do
    [ nil, false, "", "  \n\t", [], {}, [].freeze ].each { |value| assert Support.blank_value?(value), value.inspect }
    [ true, 0, "a", " a ", [ nil ], { a: nil }, :sym, Object.new ].each { |value| refute Support.blank_value?(value), value.inspect }
  end

  test "blank_value?, filled? and unless_blank agree with Support.blank_value?" do
    assert "  ".blank_value?
    assert "x".filled?
    assert_nil "".unless_blank
    assert_equal "x", "x".unless_blank
    assert_nil nil.unless_blank
    assert_equal [ 1 ], [ 1 ].unless_blank
  end

  test "reject_blank drops blank elements and blank hash values" do
    assert_equal [ "a", 0, true ], [ "a", nil, "", false, 0, " ", [], true ].reject_blank
    assert_equal({ a: 1, c: "x" }, { a: 1, b: nil, c: "x", d: "", e: {} }.reject_blank)
  end

  test "merge_deep merges nested hashes, the argument wins, and does not mutate" do
    base = { data: { action: "a", slot: "x" }, class: "one", aria: { label: "l" } }
    other = { data: { action: "b" }, class: "two", aria: nil }
    merged = base.merge_deep(other)

    assert_equal({ data: { action: "b", slot: "x" }, class: "two", aria: nil }, merged)
    assert_equal({ data: { action: "a", slot: "x" }, class: "one", aria: { label: "l" } }, base)
    assert_equal({ a: 1 }, { a: { b: 1 } }.merge_deep({ a: 1 }))
    assert_equal({ a: { b: 1 } }, { a: 1 }.merge_deep({ a: { b: 1 } }))
  end

  test "snake_case converts the names the components use" do
    {
      "tabIndex" => "tab_index", "itemID" => "item_id", "httpEquiv" => "http_equiv", "DropdownMenu" => "dropdown_menu",
      "Phlex::Shadcn::CheckItem" => "phlex/shadcn/check_item", "already_snake" => "already_snake", "kebab-case" => "kebab_case",
      "HTMLParser" => "html_parser", "className" => "class_name"
    }.each { |input, expected| assert_equal expected, input.snake_case, input }
  end

  test "unqualified keeps the last constant name" do
    assert_equal "Dialog", "Phlex::Shadcn::Dialog".unqualified
    assert_equal "Dialog", "Dialog".unqualified
  end

  test "json escapes the characters that are unsafe in HTML" do
    unsafe = "<b> & x#{[ 0x2028 ].pack('U')}"
    backslash = "\\"
    expected = [ '{"a":"', backslash, "u003cb", backslash, "u003e ", backslash, "u0026 x", backslash, 'u2028"}' ].join

    assert_equal expected, Support.json({ a: unsafe })
    assert_equal '["a","b"]', Support.json(%w[a b])
    assert_equal '{"side":"top","avoid":true,"n":null}', Support.json({ side: "top", avoid: true, n: nil })
  end
end
# rubocop:enable Minitest/AssertPredicate, Minitest/AssertWithExpectedArgument
