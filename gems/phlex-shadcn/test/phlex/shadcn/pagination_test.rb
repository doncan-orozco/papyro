# frozen_string_literal: true

require "phlex/test_case"

class Phlex::Shadcn::PaginationTest < Phlex::Shadcn::TestCase
  P = Phlex::Shadcn::Pagination

  test "root renders nav with slot and merged class" do
    out = P.new(class: "mt-4").call { |_| "x" }

    assert_includes out, 'data-slot="pagination"'
    assert_includes out, 'aria-label="pagination"'
    assert_includes out, "mt-4"
  end

  test "link is tri-state" do
    assert_not_includes P::Link.new(href: "#").call { "1" }, "data-active"
    assert_includes P::Link.new(is_active: false).call { "1" }, 'data-active="false"'
    active = P::Link.new(is_active: true).call { "1" }

    assert_includes active, 'data-active="true"'
    assert_includes active, 'aria-current="page"'
  end

  test "item class is emitted verbatim" do
    assert_includes P::Item.new(class: "p-2 p-4").call { "x" }, 'class="p-2 p-4"'
  end

  test "previous next and ellipsis" do
    assert_includes P::Previous.new(href: "#", size: :lg).call, "Previous"
    assert_includes P::Next.new(href: "#").call, 'aria-label="Go to next page"'
    assert_includes P::Ellipsis.new.call, "More pages"
  end

  test "helpers render the same HTML as the explicit classes" do
    helper = P.new.call do |p|
      p.content { p.item { p.previous(href: "#") } }
    end
    explicit = P.new.call do |p|
      p.render(P::Content.new) { p.render(P::Item.new) { p.render P::Previous.new(href: "#") } }
    end

    assert_equal explicit, helper
  end

  test "link size and active states" do
    sized = P::Link.new(size: "default", href: "#").call { "x" }
    active = P::Link.new(is_active: true, href: "#").call { "2" }

    assert_includes sized, "px-4"
    assert_includes active, 'aria-current="page"'
    assert_includes active, 'data-active="true"'
    assert_includes P::Link.new(href: "#").call { "x" }, "data-slot=\"pagination-link\""
  end

  test "every helper renders the same HTML as the explicit part" do
    { link: P::Link, next: P::Next, ellipsis: P::Ellipsis, item: P::Item, content: P::Content }.each do |name, klass|
      helper = P.new.call { |p| p.public_send(name, class: "z") { "x" } }
      explicit = P.new.call { |p| p.render(klass.new(class: "z")) { "x" } }

      assert_equal explicit, helper, name.to_s
    end
  end
end
