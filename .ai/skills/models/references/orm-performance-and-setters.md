# ORM Performance and Setter Shims

## MANDATORY RULE: ORM Performance & Memory (N+1 Prevention)

### In-Memory Finding Pattern

When querying a `has_many` association **from within an instance method**, assume the association might already be eager-loaded in memory (via `.includes` in a Query Object or controller).

**Do NOT use `.find_by` or `.where` inside instance methods if evaluating a loaded association. It will trigger an N+1 database query directly to the database even if the association was already eager-loaded.**

**Use the Ruby enumerable `.find` to search the loaded array in memory. Only fall back to `.find_by` if you know the association was not pre-loaded.**

### Forbidden — Hidden N+1 Query

```ruby
# FORBIDDEN — Triggers an N+1 database query for every article
# even if article_translations were already eager-loaded
def original_translation_published?
  article_translations.find_by(locale: original_locale)&.published?
end

# Usage in controller:
# articles = Articles::PublishedQuery.call.includes(:article_translations)
# articles.each { |a| a.original_translation_published? }  # N+1 queries!
```

### Correct — Searches Memory First, Falls Back

```ruby
# CORRECT — Searches the loaded memory array; zero N+1s
def original_translation_published?
  translation = if association(:article_translations).loaded?
    article_translations.find { |item| item.locale == original_locale }
  else
    article_translations.find_by(locale: original_locale)
  end
  translation&.published? || false
end
```

The pattern:
1. Check if the association is already loaded: `association(:article_translations).loaded?`
2. If loaded, search the in-memory array with `.find { ... }`
3. If not loaded, fall back to `.find_by` for a single query

This pattern is safe and performant whether or not the association was pre-loaded.

---

## MANDATORY RULE: Never Create Setter Shims

**Do not create `attr_writer` or setter methods for attributes that are not stored in the model.**

If an attribute is not a real database column or derived state that you own, do not create a setter. The model will naturally reject unknown attributes, which is the correct behavior.

### Forbidden — The Setter Shim Anti-Pattern

```ruby
# FORBIDDEN — This looks like the model owns "status", but it doesn't
def status=(value)
  # Absorbs the assignment silently; caller has no idea it's ignored
  @status = value
end

# Later, when callers try to mass-assign:
article.assign_attributes(status: "draft")  # Silently ignored; no error
```

This creates a **leaky abstraction**:
- The model claims to accept `status:`, but doesn't persist it
- Callers have no feedback that their input was discarded
- Tests pass because the assignment doesn't raise an error
- Later refactors break silently

### Correct — Let the Model Reject Unknown Attributes

```ruby
# CORRECT — No setter
class Article < ApplicationRecord
  def status
    return "archived" if archived?
    return "published" if published?
    "draft"
  end

  # No status= method
end

# If code tries to mass-assign status, it fails loudly:
article.assign_attributes(status: "draft")
# => ActiveModel::UnknownAttributeError: unknown attribute 'status' for Article.

# This error is the correct signal: handle intent in the Operation layer
```

**The right place to handle `status:` input:** In the operation, extract it **before** mass-assigning to the model.

```ruby
# app/concepts/articles/operation/create.rb
module Articles
  module Operation
    class Create < Core::Operation
      def call(params:, user:)
        # Extract intent BEFORE model mass-assignment
        publish_requested = params[:status].to_s == "published"
        
        # Validate that if publishing, published_at is present
        if publish_requested && params[:published_at].blank?
          model = Article.new(params.except(:status))
          model.errors.add(:published_at, I18n.t("errors.messages.published_at_required_for_published"))
          return fail_with_model!(model)
        end

        # Strip status before persistence
        article = user.articles.build(params.except(:status))
        
        return Success(article) if article.save
        fail_with_model!(article)
      end
    end
  end
end
```

---
