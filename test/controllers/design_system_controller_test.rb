require "test_helper"

class DesignSystemControllerTest < ActionDispatch::IntegrationTest
  test "index is accessible without authentication" do
    get design_system_path

    assert_response :success
  end

  test "react catalog is accessible without authentication" do
    get design_system_react_path

    assert_response :success
  end

  test "react catalog renders iframe with correct src" do
    get design_system_react_path

    assert_response :success
    assert_select "iframe[src='/react-catalog/']"
    assert_select "h1", text: "React shadcn/ui Catalog"
  end

  test "compare view is accessible without authentication" do
    get design_system_compare_path

    assert_response :success
  end

  test "compare view renders header and title" do
    get design_system_compare_path

    assert_response :success
    assert_select "h1", text: "Component Comparison: React vs Phlex"
  end

  test "compare view renders both catalog iframes" do
    get design_system_compare_path

    assert_select "iframe[src='/react-catalog/']"
    assert_select "iframe[src='/design-system']"
    assert_select ".grid-cols-2"
  end

  test "react catalog has navigation links" do
    get design_system_react_path

    assert_response :success
    assert_select "a[href='#{design_system_path}']", text: /Phlex Catalog/
    assert_select "a[href='#{design_system_compare_path}']", text: /Compare Side-by-Side/
  end

  test "compare view has navigation links" do
    get design_system_compare_path

    assert_response :success
    assert_select "a[href='#{design_system_path}']", text: /Phlex Catalog/
    assert_select "a[href='#{design_system_react_path}']", text: /React Catalog/
  end

  test "the catalog renders svg icons" do
    get design_system_path

    assert_select "svg", minimum: 1
  end

  test "the catalog lists every ported chadcn component with a preview, without authentication" do
    get design_system_path

    assert_response :success
    assert_select "h1", text: "V2 Component Catalog"
    assert_select "section#v2-button [data-slot=button]"
    assert_select "section#v2-dialog [data-slot=dialog-trigger]"
    assert_select "nav a[href='#v2-tooltip']"
    assert_select "section[id^=v2-]", count: Components::Parity::Catalog.entries.size
  end

  test "the old v2 address redirects permanently to the catalog and keeps the query" do
    get design_system_v2_path(locale: :es)

    assert_response :moved_permanently
    assert_redirected_to "#{design_system_path}?locale=es"
  end

  test "every design system locale key exists in English and Spanish" do
    english = locale_keys(:en)

    assert_equal english, locale_keys(:es)
    assert_not_includes english, "page.title", "keys only the legacy catalog used must be gone"
  end

  private

  def locale_keys(locale)
    flatten_keys(YAML.load_file(Rails.root.join("config/locales/#{locale}/design_system.yml")).dig(locale.to_s, "design_system"))
  end

  def flatten_keys(tree, prefix = nil)
    tree.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? flatten_keys(value, path) : [ path ]
    end.sort
  end
end
