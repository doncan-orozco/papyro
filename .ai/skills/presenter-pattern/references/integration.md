# Controller and View Integration

## Controller Integration

Controllers build and pass presenters to views. They do NOT use presenters internally for business logic.

```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]

  def index
    scoped_articles = policy_scope(Article)
    articles = Articles::Query::Published.call({}, scope: scoped_articles).limit(6)

    # Use base presenter for collections
    presented_articles = Articles::Presenter::Default.wrap(articles, locale: I18n.locale)

    render Views::Articles::Index.new(
      articles: presented_articles,
      show_welcome_hero: Current.user.guest?
    )
  end

  def show
    article = find_published_article_by_slug!
    authorize article

    more_from_author = Articles::Query::Related.call(user: article.user, article_id: article.id, limit: 2)
    more_from_platform = Articles::Query::Related.call(exclude_user_id: article.user_id, article_id: article.id, limit: 2)

    # Single presenter
    render Views::Articles::Show.new(
      article: Articles::Presenter::Show.new(
        article,
        more_from_author: more_from_author,
        more_from_platform: more_from_platform,
        locale: I18n.locale
      )
    )
  end
end
```

---

## View Integration (Phlex)

In your Phlex view, the presenter appears as a regular model object with super-powers.

```ruby
# app/views/articles/show.rb
module Views
  module Articles
    class Show < Views::Base
      def initialize(article:, more_from_author: [], more_from_platform: [])
        @article = article  # This is actually a presenter
        @more_from_author = more_from_author
        @more_from_platform = more_from_platform
      end

      def view_template
        div(class: "space-y-4") do
          # Presenter methods are indistinguishable from model methods
          h1(class: "text-3xl font-bold") { @article.display_title }
          p(class: "text-muted-foreground") { @article.published_at_label }

          # Presenter can provide view-ready data
          if @article.continuation_articles.any?
            h2 { @article.continuation_heading }
            div(class: "grid grid-cols-2") do
              @article.continuation_articles.each do |related|
                render Articles::ArticleCard.new(article: related)
              end
            end
          end

          # Presenter logic is used to make decisions
          if @article.locale_published?(translation)
            render Components::Ui::Badge.new { "Published" }
          end
        end
      end
    end
  end
end
```

---
