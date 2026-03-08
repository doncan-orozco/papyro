require "test_helper"

module Admin
  class ArticlesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:admin)
      sign_in_as(@user)
      @article = Article.create!(
        title: "Test Article",
        slug: "test-article",
        status: :draft,
        body: "<p>Test content</p>",
        user: @user
      )
    end

    test "index renders successfully" do
      get admin_articles_path

      assert_response :success
    end

    test "new renders form" do
      get new_admin_article_path

      assert_response :success
    end

    test "create with valid params redirects to index" do
      assert_difference("Article.count", 1) do
        post admin_articles_path, params: {
          article: {
            title: "New Article",
            slug: "new-article",
            status: "draft",
            body: "<p>New content</p>"
          }
        }
      end

      assert_redirected_to admin_articles_path
      assert_equal I18n.t("admin.articles.operations.create.success"), flash[:notice]
    end

    test "create with invalid params renders new" do
      assert_no_difference("Article.count") do
        post admin_articles_path, params: {
          article: {
            title: "",
            slug: "new-article",
            status: "draft"
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "edit renders form" do
      get edit_admin_article_path(id: @article.id)

      assert_response :success
    end

    test "update with valid params redirects to index" do
      patch admin_article_path(id: @article.id), params: {
        article: {
          title: "Updated Title",
          slug: "updated-slug",
          status: "draft"
        }
      }

      assert_redirected_to admin_articles_path
      assert_equal I18n.t("admin.articles.operations.update.success"), flash[:notice]
      assert_equal "Updated Title", @article.reload.title
    end

    test "update with invalid params renders edit" do
      patch admin_article_path(id: @article.id), params: {
        article: {
          title: "",
          slug: "updated-slug",
          status: "draft"
        }
      }

      assert_response :unprocessable_entity
    end

    test "destroy deletes article and redirects" do
      assert_difference("Article.count", -1) do
        delete admin_article_path(id: @article.id)
      end

      assert_redirected_to admin_articles_path
      assert_equal I18n.t("admin.articles.operations.destroy.success"), flash[:notice]
    end

    test "publish changes status to published" do
      patch publish_admin_article_path(id: @article.id, publish_action: "publish")

      assert_redirected_to admin_articles_path
      assert_predicate @article.reload, :status_published?
      assert_not_nil @article.published_at
    end

    test "unpublish changes status to draft" do
      @article.update!(status: :published, published_at: Time.current)

      patch publish_admin_article_path(id: @article.id, publish_action: "unpublish")

      assert_redirected_to admin_articles_path
      assert_predicate @article.reload, :status_draft?
      assert_nil @article.published_at
    end

    test "requires authentication" do
      sign_out

      get admin_articles_path

      assert_redirected_to admin_login_path
    end
  end
end
