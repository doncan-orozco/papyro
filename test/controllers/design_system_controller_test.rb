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

  test "compare view renders split-screen layout" do
    get design_system_compare_path

    assert_response :success
    assert_select "h1", text: "Component Comparison: React vs Phlex"
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
end
