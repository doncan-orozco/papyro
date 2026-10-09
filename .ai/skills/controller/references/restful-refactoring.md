# RESTful Refactoring Workflow


# Rails RESTful Controllers

> **The canonical controller skill is [../controller/SKILL.md](../SKILL.md).** Load that first for the full golden archetype. This file focuses specifically on the refactoring workflow and extraction patterns for converting non-RESTful controllers.

## Core Principles

1. **Strict CRUD Only**: Controllers must ideally be limited to the default seven actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`.
2. **Resources Over Actions**: The presence of custom actions (verbs like `publish` or adjectives like `featured`) strongly indicates a hidden resource that should be extracted into its own controller.
3. **Delegated Logic**: Controllers should remain skinny. Business logic should be delegated to Operations/Service objects, database queries to Query objects, and presentation logic to View objects.

## Controller Refactoring Workflow

When asked to review, write, or refactor a Rails controller:

1. Scan the controller for any actions outside the standard 7 CRUD operations.
2. Identify the underlying resource the custom action is manipulating.
3. Extract the action into a new controller or namespace.
4. Update `config/routes.rb` to ensure routes rely on `resources` rather than custom `get/post` mappings.
   - For nested resources, prefer `resources ... do; resource ...; end` over manual `scope` path rewriting.
   - Remember that nested resource routes often use parent-scoped param keys such as `article_slug` for `/articles/:slug/...` nested routes.

**For concrete extraction strategies and code examples**, read [refactoring-patterns.md](restful-refactoring.md).

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
