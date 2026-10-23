require "test_helper"

class LayoutToasterTest < ActionDispatch::IntegrationTest
  test "application layout mounts exactly one toaster" do
    get new_session_path

    assert_response :success
    assert_select "section#toaster[data-controller='chadcn--sonner']", count: 1
  end

  # no reachable route renders the admin layout (Mission Control at /jobs brings its own), so render it directly
  test "admin layout mounts exactly one toaster" do
    html = ApplicationController.render(html: "", layout: "admin")

    assert_equal 1, Nokogiri::HTML5(html).css("section#toaster[data-controller='chadcn--sonner']").size
  end
end
