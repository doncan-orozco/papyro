require "test_helper"
require "securerandom"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @ruby_article = Article.create!(
      title: "Learning Ruby on Rails",
      slug: "lror-#{Time.current.to_i}",
      excerpt: "Ruby excerpt",
      body: "<p>Ruby content</p>",
      user: @user
    )
    publish_article!(@ruby_article)
    @python_article = Article.create!(
      title: "Python for beginners",
      slug: "pfb-#{Time.current.to_i}",
      excerpt: "Python excerpt",
      body: "<p>Python content</p>",
      user: @user
    )
    publish_article!(@python_article)
  end

  test "search is accessible without authentication" do
    get search_path(q: "Ruby")

    assert_response :success
  end

  test "search returns matching articles" do
    get search_path(q: "Ruby")

    assert_response :success
    assert_includes @response.body, @ruby_article.title
    assert_not_includes @response.body, @python_article.title
  end

  test "search returns matching authors" do
    get search_path(q: "Reader")

    assert_response :success
    assert_includes @response.body, "Reader One"
  end

  test "search with no matches shows empty state" do
    get search_path(q: "xyznonexistent")

    assert_response :success
    assert_includes @response.body, "No results found for"
    assert_includes @response.body, "xyznonexistent"
  end

  test "search returns turbo-frame response" do
    get search_path(q: "Ruby")

    assert_response :success
    assert_includes @response.body, 'turbo-frame id="search_results"'
  end
end
