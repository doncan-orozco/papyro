require "test_helper"

class Views::Authors::Show::PaginationTest < ActiveSupport::TestCase
  FakePagy = Struct.new(:previous, :next, :series)

  test "renders page links, the current page and both neighbours" do
    nav = render_nav(FakePagy.new(1, 3, [ 1, "2", 3 ]))

    assert_equal "pagination", nav["aria-label"]
    assert_equal "/@ana?page=1", previous_link(nav)["href"]
    assert_equal "/@ana?page=3", next_link(nav)["href"]
    assert_equal %w[/@ana?page=1 /@ana?page=3], page_links(nav).filter_map { |link| link["href"] }

    current = nav.at_css("[aria-current='page']")

    assert_equal "2", current.text.strip
    assert_nil current["href"]
  end

  test "marks previous and next as disabled at the edges" do
    first = render_nav(FakePagy.new(nil, 2, [ "1", 2 ]))

    assert_nil previous_link(first)["href"]
    assert_equal "true", previous_link(first)["aria-disabled"]
    assert_nil next_link(first)["aria-disabled"]

    last = render_nav(FakePagy.new(1, nil, [ 1, "2" ]))

    assert_nil next_link(last)["href"]
    assert_equal "true", next_link(last)["aria-disabled"]
    assert_nil previous_link(last)["aria-disabled"]
  end

  test "localizes the visible labels and the gap label in Spanish" do
    nav = I18n.with_locale(:es) { render_nav(FakePagy.new(1, 3, [ 1, :gap, "5", 3 ])) }

    assert_includes previous_link(nav).text, I18n.t("design_system.pagination.previous", locale: :es)
    assert_includes next_link(nav).text, I18n.t("design_system.pagination.next", locale: :es)
    assert_equal I18n.t("design_system.pagination.more_pages", locale: :es),
      nav.at_css("[data-slot='pagination-ellipsis'] .sr-only").text
  end

  private

  def render_nav(pagy)
    html = ApplicationController.render(Views::Authors::Show::Pagination.new(pagy: pagy, username: "ana"), layout: false)
    Nokogiri::HTML5.fragment(html).at_css("nav")
  end

  def previous_link(nav) = nav.at_css("a[aria-label='Go to previous page']")

  def next_link(nav) = nav.at_css("a[aria-label='Go to next page']")

  def page_links(nav) = nav.css("[data-slot='pagination-link']:not([aria-label])")
end
