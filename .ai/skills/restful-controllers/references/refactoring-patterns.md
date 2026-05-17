# RESTful Refactoring Patterns

This reference contains standard patterns for converting custom Rails controller actions into strictly RESTful resources.

## Pattern 1: Context Splitting (Namespaces)

**Trigger:** The controller mixes public consumption (e.g., viewing all articles) with private administration (e.g., a user managing their own articles via a `mine` or `dashboard` action).

**Solution:** Extract the administrative actions into a dedicated namespace (e.g., `Admin::`, `My::`, or `Dashboard::`). 

**Before (Anti-pattern):**
```ruby
class ArticlesController < ApplicationController
  def index # Public
    @articles = Article.published
  end

  def mine # Private / Custom action
    @articles = Current.user.articles
  end
end
```

**After (RESTful):**
```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def index
    @articles = Article.published
  end
end

# app/controllers/admin/articles_controller.rb
class Admin::ArticlesController < ApplicationController
  def index
    @articles = Current.user.articles
  end
end
```

## Pattern 2: State Changes as Resources

**Trigger:** The controller uses a custom verb action to change the state of a model (e.g., `publish`, `archive`, `approve`, `cancel`).

**Solution:** Treat the state change as the creation or destruction of a sub-resource.

**Before (Anti-pattern):**
```ruby
class ArticlesController < ApplicationController
  def publish
    @article = Article.find(params[:id])
    @article.update(status: :published)
  end
end
```

**After (RESTful):**
```ruby
# app/controllers/article_publications_controller.rb
class ArticlePublicationsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @article.update(status: :published)
  end

  def destroy
    @article = Article.find(params[:article_id])
    @article.update(status: :draft)
  end
end
```
*Route:* `resources :articles { resource :publication, only: [:create, :destroy] }`

## Pattern 3: Scoped Collections

**Trigger:** The controller has custom adjective actions that merely filter a collection (e.g., `featured`, `popular`, `recent`).

**Solution:** * **Approach A (Simple):** Pass a query parameter to the standard `index` action (e.g., `GET /articles?filter=featured`).
* **Approach B (Complex):** If the scoped collection requires different authorization, layouts, or entirely different views, create a dedicated controller.

**Before (Anti-pattern):**
```ruby
class ArticlesController < ApplicationController
  def featured
    @articles = Article.where(featured: true)
  end
end
```

**After (RESTful Approach B):**
```ruby
# app/controllers/featured_articles_controller.rb
class FeaturedArticlesController < ApplicationController
  def index
    @articles = Article.where(featured: true)
  end
end
```
*Route:* `resources :featured_articles, only: [:index]`
