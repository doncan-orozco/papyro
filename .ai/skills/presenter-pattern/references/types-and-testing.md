# Presenter Types and Testing

## Common Presenter Types

### 1. Domain Presenters (Single Model)

Wraps a single model with display methods shared across many views.

```ruby
module Articles
  module Presenter
    class Default < SimpleDelegator
  def initialize(article, locale: I18n.locale)
    super(article)
    @locale = locale
  end
  
  def display_title
    # Locale-aware title selection
  end
    end
  end
end
```

### 2. Aggregate Presenters (Related Models)

Wraps a primary model plus related data (but NOT nested presenters).

```ruby
module Authors
  module Presenter
    class Default < SimpleDelegator
  def initialize(profile, author:, current_user: nil)
    super(profile)
    @author = author
    @current_user = current_user
  end
  
  def bio
    super
  end
  
  def can_edit?
    @current_user&.id == @author.id
  end
    end
  end
end
```

### 3. Collection Presenters (Many Models)

Use `.wrap()` helper to present each model in a collection uniformly.

```ruby
# Controller
articles = Article.published.limit(10)
presented = Articles::Presenter::Default.wrap(articles, locale: I18n.locale)

# View iterates over presented articles
@articles.each do |article|
  render ArticleCard.new(article: article)  # article is a presenter
end
```

---

## Testing Presenters

Presenters are tested like any other Ruby object:

```ruby
class Articles::Presenter::ShowTest < ActiveSupport::TestCase
  test "display title falls back to original locale" do
    article = Article.create!(title: "Test", slug: "test-#{SecureRandom.hex(4)}", body: "Body", user: users(:admin))
    presenter = Articles::Presenter::Default.new(article, locale: :fr)

    assert_equal "Test", presenter.display_title
  end

  test ".wrap builds presenter collection" do
    articles = [ articles(:draft_article), articles(:published_article) ]
    presenters = Articles::Presenter::Default.wrap(articles, locale: :es)

    assert_equal 2, presenters.length
    assert presenters.all? { |presenter| presenter.is_a?(Articles::Presenter::Default) }
  end
end
```

---
