# ApplicationQuery Base Class and Examples

### The ApplicationQuery Base Class
*(This exists in `app/queries/application_query.rb`)*
```ruby
class ApplicationQuery
  def self.pipeline(*steps)
    @pipeline_steps = steps.flatten
  end

  def self.pipeline_steps
    @pipeline_steps ||= []
  end

  def self.base_scope(&block)
    @base_scope_proc = block
  end

  def self.evaluated_base_scope
    raise NotImplementedError, "Define a `base_scope` block in #{name}" unless @base_scope_proc
    @base_scope_proc.call
  end

  def self.call(filters = {}, scope: nil)
    initial_scope = scope || evaluated_base_scope
    new(filters, scope: initial_scope).build_query
  end

  attr_reader :filters, :initial_scope

  def initialize(filters, scope:)
    # Protect pipeline steps from symbol/string key mismatches when callers
    # pass ActionController::Parameters or plain hashes.
    @filters = (filters || {}).to_h.with_indifferent_access
    @initial_scope = scope
  end

  def build_query
    self.class.pipeline_steps.reduce(initial_scope) do |current_scope, step|
      send(step, current_scope)
    end
  end
end
```

### Primary House Style Example
```ruby
# app/queries/articles/published_query.rb
module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_status,
             :search_by_title,
             :filter_by_category,
             :apply_ordering

    private

    def filter_by_status(current_scope)
      current_scope.where(status: :published)
    end

    def search_by_title(current_scope)
      return current_scope if filters[:query].blank?
      
      safe_query = ActiveRecord::Base.sanitize_sql_like(filters[:query].to_s.downcase)
      current_scope.where("LOWER(articles.title) LIKE ?", "%#{safe_query}%")
    end

    def filter_by_category(current_scope)
      return current_scope if filters[:category_id].blank?
      current_scope.where(category_id: filters[:category_id])
    end

    def apply_ordering(current_scope)
      field = filters.dig(:order, :field)&.to_s
      return current_scope if field.blank? || %w[created_at title].exclude?(field)
      
      dir = (filters.dig(:order, :dir)&.to_s&.downcase == "asc") ? "asc" : "desc"
      current_scope.order(field => dir)
    end
  end
end
```

## Caller Contract
Callers (usually controllers) must define and pass a `filters` hash method. The controller is responsible for choosing the correct Domain Query based on the current context.

```ruby
# In a public controller protecting drafts
def index
  relation = Articles::PublishedQuery.call(filters)
  # ... pagination and rendering
end

# In a private studio controller showing a writer's drafts
def index
  relation = Articles::OwnedQuery.call(filters.merge(owner: current_user))
  # ... pagination and rendering
end
```

## Recommended Shape (Complex Example)
```ruby
# app/queries/courses/question_banks/accessible_query.rb
module Courses::QuestionBanks
  class AccessibleQuery < ApplicationQuery
    SORTABLE_FIELDS = %w[title created_at updated_at].freeze

    base_scope { Courses::QuestionBank.all }

    pipeline :enforce_account_isolation,
             :filter_by_visibility,
             :search_by_title,
             :apply_ordering

    private

    def enforce_account_isolation(current_scope)
      return current_scope.none if filters[:site].blank?
      
      current_scope.joins(:site).where(sites: { account_id: filters[:site].account_id })
    end

    def filter_by_visibility(current_scope)
      return current_scope.none if filters[:site].blank? || filters[:user].blank?

      local_banks = current_scope.where(
        shared_type: Courses::QuestionBank::SHARED_TYPES[:LOCAL],
        site_id: filters[:site].id
      )

      global_banks = current_scope.where(
        shared_type: Courses::QuestionBank::SHARED_TYPES[:GLOBAL]
      )

      private_banks = current_scope.where(
        shared_type: Courses::QuestionBank::SHARED_TYPES[:PRIVATE],
        author_id: filters[:user].id
      )

      local_banks.or(global_banks).or(private_banks)
    end

    def search_by_title(current_scope)
      return current_scope if filters[:query].blank?

      safe_query = ActiveRecord::Base.sanitize_sql_like(filters[:query].to_s.downcase)
      current_scope.where("LOWER(courses_question_banks.title) LIKE ?", "%#{safe_query}%")
    end

    def apply_ordering(current_scope)
      field = filters.dig(:order, :field)&.to_s
      return current_scope if field.blank? || SORTABLE_FIELDS.exclude?(field)

      dir = (filters.dig(:order, :dir)&.to_s&.downcase == "asc") ? "asc" : "desc"
      current_scope.order(field => dir)
    end
  end
end
```

### Controller Pagination (caller responsibility)
```ruby
question_banks = Courses::QuestionBanks::AccessibleQuery.call(filters)
  .paginate(page: parse_page(params[:page]), per_page: parse_per_page(params[:per_page]))
```
