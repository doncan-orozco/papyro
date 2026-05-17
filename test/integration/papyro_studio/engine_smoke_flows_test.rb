require "test_helper"

module PapyroStudio
  class EngineSmokeFlowsTest < ActionDispatch::IntegrationTest
    setup do
      host! "studio.lvh.me"
      @user = users(:admin)
      sign_in_as(@user)
    end

    test "index flow responds successfully" do
      get studio_articles_path

      assert_response :success
    end

    test "edit flow responds successfully" do
      article = build_article!(slug: "engine-smoke-edit")

      get edit_studio_article_path(article.uuid)

      assert_response :success
    end

    test "publish flow publishes article" do
      article = build_article!(slug: "engine-smoke-publish")

      post studio_article_publication_path(article.uuid)

      assert_redirected_to studio_articles_path
      assert_predicate article.reload, :published?
    end

    test "unpublish flow unpublishes article" do
      article = build_article!(slug: "engine-smoke-unpublish")
      publish_article!(article)

      delete studio_article_publication_path(article.uuid)

      assert_redirected_to studio_articles_path
      assert_predicate article.reload, :draft?
      assert_nil article.published_at
    end

    test "restore flow restores trashed article" do
      article = build_article!(slug: "engine-smoke-restore", deleted_at: Time.current)

      post studio_article_restoration_path(article.uuid)

      assert_redirected_to studio_articles_path(tab: "trash")
      assert_nil article.reload.deleted_at
    end

    test "purge flow permanently deletes trashed article" do
      article = build_article!(slug: "engine-smoke-purge", deleted_at: Time.current)

      assert_difference("Article.count", -1) do
        delete studio_article_trashed_article_path(article.uuid)
      end

      assert_redirected_to studio_articles_path(tab: "trash")
    end

    test "translation publish flow publishes requested locale" do
      article = build_article!(slug: "engine-smoke-translation-publish")
      publish_article!(article)
      seed_spanish_translation!(article, status: :draft, published_at: nil)

      post studio_article_translation_publication_path(article.uuid), params: { content_locale: "es" }

      assert_redirected_to edit_studio_article_path(article.uuid, content_locale: "es")
      assert_predicate article.article_translations.find_by!(locale: "es").reload, :published?
    end

    test "translation unpublish flow unpublishes requested locale" do
      article = build_article!(slug: "engine-smoke-translation-unpublish")
      publish_article!(article)
      seed_spanish_translation!(article, status: :published, published_at: Time.current)

      delete studio_article_translation_publication_path(article.uuid), params: { content_locale: "es" }

      assert_redirected_to edit_studio_article_path(article.uuid, content_locale: "es")
      assert_predicate article.article_translations.find_by!(locale: "es").reload, :draft?
    end

    private

    def build_article!(slug:, deleted_at: nil)
      Article.create!(
        title: "Engine Smoke #{slug}",
        slug: slug,
        excerpt: "Smoke excerpt",
        body: "<p>Smoke body</p>",
        user: @user,
        deleted_at: deleted_at
      )
    end

    def seed_spanish_translation!(article, status:, published_at:)
      I18n.with_locale(:es) do
        article.update!(
          title: "Titulo #{article.slug}",
          slug: "#{article.slug}-es",
          excerpt: "Resumen #{article.slug}"
        )
      end
      article.article_translations.find_by!(locale: "es").update!(status: status, published_at: published_at)
    end
  end
end
