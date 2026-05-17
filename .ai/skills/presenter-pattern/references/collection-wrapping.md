# Collection Wrapping with Presenters

This reference shows the preferred wrapping boundary after the ArticlePresenter/ShowPresenter split.

## Core Rule

Use `Articles::Presenter::ArticlePresenter.wrap(...)` for collections.
Use `Articles::Presenter::ShowPresenter` only for the show page's main article context.

## Base Presenter Pattern

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

    def translation_fallback?
      locale.to_s != original_locale.to_s && !translation_published?(locale)
    end
  end
  end
end
```

## Controller Usage

### Index (collection)

```ruby
class ArticlesController < ApplicationController
  def index
    articles = Articles::Query::Published.call({}, scope: policy_scope(Article)).limit(10)
    presented_articles = Articles::Presenter::ArticlePresenter.wrap(articles, locale: I18n.locale)

    render Views::Articles::Index.new(articles: presented_articles)
  end
end
```

### Show (single + related collections)

```ruby
class ArticlesController < ApplicationController
  def show
    article = find_published_article_by_slug!
    authorize article

    more_from_author = Articles::Query::Related.call(user: article.user, article_id: article.id, limit: 2)
    more_from_platform = Articles::Query::Related.call(exclude_user_id: article.user_id, article_id: article.id, limit: 2)

    presenter = Articles::Presenter::ShowPresenter.new(
      article,
      more_from_author: more_from_author,
      more_from_platform: more_from_platform,
      locale: I18n.locale
    )

    render Views::Articles::Show.new(presenter: presenter)
  end
end
```

`ShowPresenter` wraps related collections internally with `ArticlePresenter.wrap`, so cards get the lightweight base presenter.

## Query Guardrail

If presenter methods touch `user.profile`, preload it in the query used by the flow.

```ruby
# example for slug query used by show
scope.joins(:article_translations).includes(user: :profile)
```

## Test Pattern

```ruby
# test/presenters/articles/article_presenter_test.rb
test "wrap builds presenters for collections" do
  articles = [articles(:draft_article), articles(:published_article)]
  presenters = assert_wraps_collection(Articles::Presenter::ArticlePresenter, articles, locale: :es)

  assert presenters.all?(&:translation_fallback?)
end
```

See [../SKILL.md](../SKILL.md) for the full presenter rules.
