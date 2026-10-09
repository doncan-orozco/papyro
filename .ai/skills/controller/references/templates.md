# Controller Templates

Full examples referenced from `../SKILL.md`.

## Turbo Stream Pattern

When an action must respond to both HTML and Turbo Stream:

```ruby
def update
  result = Mobility.with_locale(content_locale) do
    Articles::Operation::Update.new.call(model: article, params: article_params.to_h, locale: content_locale)
  end

  if result.success?
    updated_article = result.value![:model]
    respond_to do |format|
      format.html { redirect_to studio_articles_path, notice: t("studio.articles.operations.update.success") }
      format.turbo_stream { render "studio/articles/update_success", locals: { updated_article:, content_locale: } }
    end
  else
    invalid_article = result.failure[:model]
    respond_to do |format|
      format.html do
        Mobility.with_locale(content_locale) do
          render Views::Studio::Articles::Edit.new(article: invalid_article, content_locale:), status: :unprocessable_entity
        end
      end
      format.turbo_stream do
        render "studio/articles/update_autosave_status", locals: { status: :failed }, status: :unprocessable_entity
      end
    end
  end
end
```

## Full RESTful Controller Template

```ruby
# frozen_string_literal: true

class Studio::ArticlesController < Studio::BaseController
  before_action :authorize_article, only: %i[edit update destroy]

  def index
    skip_policy_scope
    articles = Articles::OwnedQuery.call(user: Current.user, tab: params[:tab])
    pagy, articles = pagy(articles, page: parse_page, limit: 10)
    render Views::Studio::Articles::Index.new(articles: articles, pagy: pagy, params: params)
  end

  def create
    authorize Article, policy_class: Studio::ArticlePolicy
    result = Mobility.with_locale(studio_content_locale) do
      Articles::Operation::Create.new.call(
        params: { title: t("studio.articles.editor.untitled"), status: "draft" },
        user: Current.user
      )
    end
    if result.success?
      redirect_to edit_studio_article_path(result.value![:model].uuid),
        notice: t("studio.articles.operations.create.success")
    else
      render Views::Studio::Articles::New.new(article: result.failure[:model]), status: :unprocessable_entity
    end
  end

  def edit
    content_locale = studio_content_locale(default: article.original_locale)
    Mobility.with_locale(content_locale) do
      render Views::Studio::Articles::Edit.new(article: article, content_locale: content_locale)
    end
  end

  def update
    content_locale = studio_content_locale(default: article.original_locale)
    result = Mobility.with_locale(content_locale) do
      Articles::Operation::Update.new.call(model: article, params: article_params.to_h, locale: content_locale)
    end
    if result.success?
      respond_to do |format|
        format.html { redirect_to studio_articles_path, notice: t("studio.articles.operations.update.success") }
        format.turbo_stream { render "studio/articles/update_success", locals: { updated_article: result.value![:model], content_locale: } }
      end
    else
      respond_to do |format|
        format.html do
          Mobility.with_locale(content_locale) do
            render Views::Studio::Articles::Edit.new(article: result.failure[:model], content_locale:), status: :unprocessable_entity
          end
        end
        format.turbo_stream { render "studio/articles/update_autosave_status", locals: { status: :failed }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    content_locale = studio_content_locale(default: article.original_locale)
    result = Articles::Operation::Destroy.new.call(model: article)
    if result.success?
      redirect_to studio_articles_path, notice: t("studio.articles.operations.destroy.success"), status: :see_other
    else
      Mobility.with_locale(content_locale) do
        render Views::Studio::Articles::Edit.new(article: result.failure[:model], content_locale:), status: :unprocessable_entity
      end
    end
  end

  private

  def article
    @article ||= Current.user.articles.find_by!(uuid: params[:uuid])
  end

  def authorize_article
    authorize article, policy_class: Studio::ArticlePolicy
  end

  def article_params
    params.require(:article).permit(:title, :slug, :body, :excerpt, :status, :published_at)
  end
end
```

---

## Non-RESTful State Transition Controller Template

```ruby
# frozen_string_literal: true

# POST /studio/articles/:article_uuid/restoration
class Studio::ArticleRestorationsController < Studio::BaseController
  def create
    authorize article, :restore?, policy_class: Studio::ArticlePolicy
    result = Articles::Operation::Restore.new.call(model: article)
    if result.success?
      redirect_to studio_articles_path(tab: "trash"),
        notice: t("studio.articles.operations.restore.success"), status: :see_other
    else
      redirect_to studio_articles_path(tab: "trash"),
        alert: t("studio.articles.operations.restore.failure"), status: :see_other
    end
  end

  private

  def article
    @article ||= Current.user.articles.find_by!(uuid: params[:article_uuid])
  end
end
```
