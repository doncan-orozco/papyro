require "test_helper"

class Articles::Operation::UpdateTest < ActiveSupport::TestCase
  test "updates article with valid params" do
    user = users(:admin)
    article = Article.create!(
      title: "Original Title",
      slug: "original-slug",
      user: user
    )

    params = {
      title: "Updated Title",
      slug: "updated-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "Updated Title", result.value![:model].reload.title
    assert_equal "updated-slug", result.value![:model].slug
  end

  test "updates article content" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      body: "<p>Original content</p>",
      user: user
    )

    params = {
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      body: "<p>Updated content</p>"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_includes result.value![:model].reload.body.to_html, "Updated content"
    assert_equal "<p>Updated content</p>", result.value![:model].reload.body.content.to_s
  end

  test "updates markdown body" do
    user = users(:admin)
    article = Article.create!(
      title: "Body Update Article",
      slug: "body-update-article",
      body: "Old body",
      user: user
    )

    params = {
      title: "Body Update Article",
      slug: "body-update-article",
      status: "draft",
      body: "# New Markdown"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "# New Markdown", result.value![:model].reload.body.content.to_s
  end

  test "keeps existing markdown content when body param is omitted" do
    user = users(:admin)
    article = Article.create!(
      title: "Article With Body",
      slug: "article-with-body",
      body: "# Existing Body",
      user: user
    )

    params = {
      title: "Renamed Article",
      slug: "article-with-body",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "# Existing Body", result.value![:model].reload.body.content.to_s
    refute_match(/#<ActionText::Markdown:/, result.value![:model].reload.body.content.to_s)
  end

  test "fails with invalid id" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      user: user
    )

    params = {
      title: "",  # Invalid - title blank
      slug: "test",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors], :present?
  end

  test "adds suffix when duplicate slug collides" do
    user = users(:admin)
    Article.create!(
      title: "Existing Article",
      slug: "existing-slug",
      user: user
    )
    article = Article.create!(
      title: "Test Article",
      slug: "test-slug",
      user: user
    )

    params = {
      title: "Test Article",
      slug: "existing-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_match(/\Aexisting-slug-[a-z0-9]{6}\z/, result.value![:model].reload.slug)
  end

  test "allows same slug for same article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-slug",
      user: user
    )

    params = {
      title: "Updated Title",
      slug: "test-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
  end

  test "fails when trying to reassign user_id" do
    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Test Article",
      slug: "test-slug-reassign",
      user: user
    )

    params = {
      title: "Test Article",
      slug: "test-slug-reassign",
      status: "draft",
      user_id: other_user.id # Attempting to change ownership
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    # user_id should remain unchanged (excluded by operation)
    assert_equal user.id, article.reload.user_id
  end

  test "auto-regenerates slug for draft when title changes without explicit slug" do
    user = users(:admin)
    article = Article.create!(
      title: "Original Draft Title",
      slug: "original-draft-title-aaaaaa",
      user: user
    )

    params = {
      title: "Updated Draft Title",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "updated-draft-title", result.value![:model].reload.slug
  end

  test "keeps explicit slug override for draft" do
    user = users(:admin)
    article = Article.create!(
      title: "Draft Title",
      slug: "draft-title-aaaaaa",
      user: user
    )

    params = {
      title: "Updated Draft Title",
      slug: "custom-editor-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "custom-editor-slug", result.value![:model].reload.slug
  end

  test "adds suffix when explicit draft slug collides" do
    user = users(:admin)
    Article.create!(
      title: "Existing",
      slug: "japan-travel-guide",
      user: user
    )

    article = Article.create!(
      title: "Draft Title",
      slug: "draft-title",
      user: user
    )

    params = {
      title: "Updated Draft Title",
      slug: "japan-travel-guide",
      status: "draft"
    }

    operation_class = Class.new(Articles::Operation::Update) do
      define_method(:random_slug_suffix) { "k9f2m1" }
    end

    result = operation_class.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "japan-travel-guide-k9f2m1", result.value![:model].reload.slug
  end

  test "blocks slug changes for published articles" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Title",
      slug: "published-title-aaaaaa",
      excerpt: "Published excerpt",
      body: "<p>Published body</p>",
      user: user
    )
    publish_article!(article)

    article.update!(original_locale: "en")

    params = {
      title: "Published Title Updated",
      slug: "new-published-slug",
      status: "published"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:slug], :any?
    assert_includes result.failure[:errors][:slug], I18n.t("studio.articles.operations.update.slug_locked")
    assert_equal "published-title-aaaaaa", article.reload.slug
  end

  test "allows slug changes for non-original locale when translation is not approved" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Title",
      slug: "published-title-en",
      excerpt: "Published excerpt",
      body: "<p>Published body</p>",
      published_at: Time.current,
      user: user
    )

    publish_article!(article)

    I18n.with_locale(:es) do
      article.update!(title: "Titulo en borrador", slug: "titulo-es-borrador")
    end

    article.update!(original_locale: "en")
    article.article_translations.find_by!(locale: "en").update!(status: :published)
    article.article_translations.find_by!(locale: "es").update!(status: :draft)

    result = I18n.with_locale(:es) do
      Articles::Operation::Update.new.call(
        model: article,
        params: {
          title: "Titulo en borrador",
          slug: "titulo-es-editable",
          status: "published"
        }
      )
    end

    assert_predicate result, :success?
    assert_equal "titulo-es-editable", I18n.with_locale(:es) { article.reload.slug }
  end

  test "blocks slug changes for published original locale even when original locale is spanish" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Title",
      slug: "published-title-en",
      excerpt: "Published excerpt",
      body: "<p>Published body</p>",
      published_at: Time.current,
      user: user
    )

    publish_article!(article)

    I18n.with_locale(:es) do
      article.update!(title: "Titulo original", slug: "titulo-original-es")
    end

    article.update!(original_locale: "es")
    article.article_translations.find_by!(locale: "en").update!(status: :draft)
    article.article_translations.find_by!(locale: "es").update!(status: :published)

    result = I18n.with_locale(:es) do
      Articles::Operation::Update.new.call(
        model: article,
        params: {
          title: "Titulo original actualizado",
          slug: "nuevo-slug-es",
          status: "published"
        }
      )
    end

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:slug], :any?
    assert_equal "titulo-original-es", I18n.with_locale(:es) { article.reload.slug }
  end

  test "blocks slug changes for approved locale translation" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Title",
      slug: "published-title-en",
      excerpt: "Published excerpt",
      body: "<p>Published body</p>",
      published_at: Time.current,
      user: user
    )

    publish_article!(article)

    I18n.with_locale(:es) do
      article.update!(title: "Titulo aprobado", slug: "titulo-aprobado-es")
    end

    article.update!(original_locale: "en")
    article.article_translations.find_by!(locale: "en").update!(status: :published)
    article.article_translations.find_by!(locale: "es").update!(status: :published)

    result = I18n.with_locale(:es) do
      Articles::Operation::Update.new.call(
        model: article,
        params: {
          title: "Titulo aprobado",
          slug: "nuevo-slug-aprobado-es",
          status: "published"
        }
      )
    end

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:slug], :any?
    assert_equal "titulo-aprobado-es", I18n.with_locale(:es) { article.reload.slug }
  end
end
