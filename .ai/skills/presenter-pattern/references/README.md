# Presenter Pattern References

This folder contains concrete examples of the Golden Presenter Pattern in action across Papyro domains.

## Files

- **[studio-article-presenter.md](studio-article-presenter.md)** — Studio-specific article presenter with draft, published, and translation logic.
- **[author-profile-presenter.md](author-profile-presenter.md)** — Multi-context author profile presenter (public profile, admin view, author dashboard).
- **[collection-wrapping.md](collection-wrapping.md)** — Using `.wrap()` to present collections in controllers and views.

## Quick Pattern Review

Every presenter should:

1. Inherit from `SimpleDelegator`
2. Accept context at init time (locale, viewer, etc.)
3. Provide a `.wrap(collection, **context)` class method
4. Return simple values from display methods (no HTML, no CSS classes)
5. Delegate to the model transparently for non-display methods

For article pages specifically:

1. Use `Articles::Presenter::ArticlePresenter` for reusable article display behavior and `.wrap` collections.
2. Use `Articles::Presenter::ShowPresenter` for show-page-only composition.

## Example: Articles::Presenter::ArticlePresenter

```ruby
# app/concepts/articles/presenter/article_presenter.rb
module Articles
  module Presenter
    class ArticlePresenter < SimpleDelegator
    def self.wrap(collection, locale: I18n.locale)
      collection.map { |item| new(item, locale: locale) }
    end

    attr_reader :locale

    def initialize(article, locale: I18n.locale)
      super(article)
      @locale = locale.to_s
    end

    # Display-specific methods
    def display_title
      # Locale-aware logic
    end

    def status_label
      I18n.t("statuses.#{status}")
    end

    def translation_fallback?
      locale.to_s != original_locale.to_s && !translation_published?(locale)
    end

    private

    def translation_for(locale)
      article_translations.find { |t| t.locale.to_s == locale.to_s }
    end
  end
  end
end
```

## Example: Controller Usage

```ruby
class ArticlesController < ApplicationController
  def index
    articles = Article.published.limit(10)
    
    # Wrap collection with presenter
    presented = Articles::Presenter::ArticlePresenter.wrap(articles, locale: I18n.locale)

    render Views::Articles::Index.new(articles: presented)
  end

  def show
    article = Article.find_by_slug!(params[:slug])
    
    # Single presenter
    render Views::Articles::Show.new(
      article: Articles::Presenter::ShowPresenter.new(article, locale: I18n.locale)
    )
  end
end
```

## Example: View Usage

```ruby
# app/views/articles/show.rb
module Views
  module Articles
    class Show < Views::Base
      def initialize(article:)
        @article = article  # Is a presenter, looks like a model
      end

      def view_template
        div do
          h1 { @article.display_title }           # Presenter method
          p { @article.published_at_label }       # Presenter method
          p { @article.excerpt }                  # Delegated to model
          
          if @article.cover_image.attached?       # Delegated to model
            img(src: @article.cover_image_url)
          end
        end
      end
    end
  end
end
```

---

## When You See These Smells, Refactor to a Presenter

1. **Controller builds display strings for the view**
   ```ruby
   # ❌ Bad
   def show
     @title = article.title.upcase + " - " + article.user.name
     render article
   end
   
   # ✅ Good
   def show
     render Views::Articles::Show.new(
       article: Articles::ShowPresenter.new(article)
     )
   end
   
   # Then in presenter:
   def display_title
     "#{title.upcase} - #{user.author_display_name}"
   end
   ```

2. **View has complex locale/context checks**
   ```ruby
   # ❌ Bad (in view)
   @article.locales.map do |locale|
     if locale == @article.original_locale
       @article.title(locale: locale)
     else
       @article.translation(locale)&.title || "(not translated)"
     end
   end
   
   # ✅ Good (in presenter)
   def sorted_translations_with_fallback
     article_translations.map do |t|
       { locale: t.locale, title: t.title || title(locale: t.locale) }
     end
   end
   ```

3. **Multiple views use the same model with identical display logic**
   ```ruby
   # Use the same presenter across contexts
   class ArticlePresenter < SimpleDelegator
     def display_title
      # Works equally in studio/show, public/show, admin/index, email
     end
   end
   ```

---

## Anti-Patterns

### ❌ Presenter with CSS

```ruby
class ArticlePresenter < SimpleDelegator
  def status_badge_html
    # NO! This is view logic.
    return "<span class='badge badge-success'>Published</span>" if published?
    "<span class='badge badge-secondary'>Draft</span>"
  end
end
```

**Instead:**

```ruby
class ArticlePresenter < SimpleDelegator
  def status_variant
    # View will decide styling
    published? ? :default : :secondary
  end
end

# In view:
render Components::Ui::Badge.new(variant: @article.status_variant) do
  @article.status_label
end
```

### ❌ Presenter per View

```ruby
# ❌ Bad
class Articles::ShowPresenter < SimpleDelegator
  # Only used in show.rb
end

class Articles::IndexPresenter < SimpleDelegator
  # Only used in index.rb
end

# ✅ Good (if logic is identical)
class ArticlePresenter < SimpleDelegator
  # Used everywhere
end
```

### ❌ Nested Presenters

```ruby
class ArticlePresenter < SimpleDelegator
  def author_presenter
    # NO! Just let the view wrap the author separately
    AuthorPresenter.new(user)
  end
end

# ✅ Good
class ArticlePresenter < SimpleDelegator
  def author
    # Just return the model; view can wrap it if needed
    super  # SimpleDelegator passes through to article.author
  end
end
```

### ❌ Business Logic in Presenters

```ruby
class ArticlePresenter < SimpleDelegator
  def save_draft
    # NO! This is write logic; use an Operation
    update!(status: :draft)
  end
end

# ✅ Good (in operation)
class Articles::Operation::SaveDraft < ApplicationOperation
  def call(article:)
    article.update!(status: :draft)
    { model: article }
  end
end
```

---

## Testing Examples

### Unit Test

```ruby
# test/presenters/articles/article_presenter_test.rb
describe Articles::ArticlePresenter do
  let(:article) { Article.create!(title: "Hello", status: "published") }
  let(:presenter) { Articles::ArticlePresenter.new(article, locale: :en) }

  describe "#status_label" do
    it "returns published label for published articles" do
      assert_equal I18n.t("statuses.published"), presenter.status_label
    end

    it "returns draft label for draft articles" do
      article.update!(status: "draft")
      assert_equal I18n.t("statuses.draft"), presenter.status_label
    end
  end

  describe ".wrap" do
    it "creates presenters for all articles in collection" do
      articles = [article, Article.create!(title: "Second")]
      presented = Articles::ArticlePresenter.wrap(articles)
      
      assert_equal 2, presented.length
      assert presented.all? { |p| p.is_a?(Articles::ArticlePresenter) }
    end
  end
end
```

### Integration Test (Presenter in View)

```ruby
# test/system/articles_test.rb
describe "Article Display" do
  it "renders article with presenter-provided title" do
    article = Article.create!(title: "Test Article", status: "published")
    visit article_path(article)
    
    assert_text "Test Article"
    assert_text I18n.t("statuses.published")
  end
end
```

---

## See Also

- Full pattern documentation: [../SKILL.md](../SKILL.md)
