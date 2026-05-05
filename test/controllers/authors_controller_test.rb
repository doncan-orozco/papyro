require "test_helper"

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @profile = author_profiles(:one)
  end

  test "show is accessible without authentication" do
    get "/@#{@profile.username}"

    assert_response :success
  end

  test "show displays author name" do
    get "/@#{@profile.username}"

    assert_includes response.body, @profile.display_name
  end

  test "show does not expose email address" do
    get "/@#{@profile.username}"

    assert_not_includes response.body, @user.email_address
  end

  test "show returns 404 for unknown username" do
    get "/@unknown_nobody_ever"

    assert_response :not_found
  end

  test "show displays edit profile button for owner" do
    sign_in_as(@user)

    get "/@#{@profile.username}"

    assert_response :success
    assert_includes response.body, I18n.t("authors.show.edit_profile")
  end

  test "show does not display edit profile button for other user" do
    sign_in_as(users(:two))

    get "/@#{@profile.username}"

    assert_response :success
    assert_not_includes response.body, I18n.t("authors.show.edit_profile")
  end

  test "show displays no articles message when author has no published articles" do
    user = users(:two)
    profile = author_profiles(:two)

    get "/@#{profile.username}"

    assert_response :success
    assert_includes response.body, I18n.t("authors.show.no_articles")
  end

  test "show displays published articles" do
    article = articles(:published_article)

    get "/@#{author_profiles(:admin).username}"

    assert_response :success
    assert_includes response.body, article.title
  end

  test "show renders location and social links when present" do
    @profile.update!(
      location: "Monterrey, MX",
      website_url: "https://papyro.example",
      x_handle: "doncanlord",
      linkedin_handle: "doncan-orozco"
    )

    get "/@#{@profile.username}"

    assert_response :success
    assert_includes response.body, "Monterrey, MX"
    assert_includes response.body, "@doncanlord"
    assert_includes response.body, "href=\"https://papyro.example\""
    assert_includes response.body, "href=\"https://x.com/doncanlord\""
    assert_includes response.body, "href=\"https://linkedin.com/in/doncan-orozco\""
    assert_includes response.body, I18n.t("authors.show.website")
    assert_includes response.body, I18n.t("authors.show.linkedin")
  end
end
