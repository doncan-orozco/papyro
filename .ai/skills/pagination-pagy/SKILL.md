---
name: pagination-pagy
description: Standardize collection pagination using Pagy across both HTML views and API endpoints, keeping pagination logic in the controller layer and enforcing strict limits.
---

# Pagination Pattern (Pagy)

## Common Pagination Scenarios
- Index or list endpoints that return record collections (HTML or API)
- Consumer-controlled `page` or `per_page` parameters
- Paginating an `ActiveRecord::Relation` returned by a query object

## Responsibilities
- Parse and sanitize user-provided pagination parameters.
- Protect the database by enforcing strict maximum limits on per-page requests.
- Apply `LIMIT` and `OFFSET` to the ActiveRecord relation right before execution.
- Generate a standardized `meta` payload for API responses.
- Render accessible, safe HTML navigation links for web views.

---

## MANDATORY RULE: Pagination is a Controller Concern

**NEVER paginate inside a Query Object, Model, or Service.** Query objects and models must return plain, unpaginated `ActiveRecord::Relation` objects. Pagination represents how the client wants to *view* the data, making it strictly a presentation/controller concern. 

---

## MANDATORY RULE: Enforce a Maximum Limit

You must **never** trust a user-provided `per_page` or `limit` parameter without capping it. Allowing unbounded limits exposes the application to Denial of Service (DoS) attacks via memory exhaustion or massive database queries.

The default maximum is **100 records per page**.

---

## Shared Setup

### 1. The Controller Backend
Move the pagination helper methods into `ApplicationController` so both web and API controllers inherit the protection limits and parsing logic.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Include Pagy backend for pagination
  include Pagy::Backend

  private

  # Transforms the Pagy metadata object into our standardized API JSON shape
  def pagination_meta(pagy_object)
    {
      total_entries: pagy_object.count,
      per_page: pagy_object.limit,
      current_page: pagy_object.page,
      total_pages: pagy_object.last # .last represents total pages
    }
  end

  # Ensures page is always a positive integer, defaulting to 1
  def parse_page(page_param = params[:page])
    parsed = page_param.to_i
    parsed > 0 ? parsed : 1
  end

  # Ensures limit is a positive integer, defaults to 20, and caps at 100
  def parse_per_page(per_page_param = params[:per_page])
    parsed = per_page_param.to_i
    limit = parsed > 0 ? parsed : 20
    [limit, 100].min
  end
end
```

### 2. The View Frontend (For HTML)
To render pagination links in your views, include Pagy's frontend module in your main helper.

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Pagy::Frontend
end
```

---

## Implementation Example: API (JSON)

When responding with JSON, pass the `@pagy` object to our `pagination_meta` method to ensure a standardized response shape.

```ruby
# app/controllers/api/v1/question_banks_controller.rb
module Api::V1
  class QuestionBanksController < ApplicationController
    def index
      relation = QuestionBanksQuery.call(filters)

      @pagy, @question_banks = pagy(relation, page: parse_page, limit: parse_per_page)

      render json: @question_banks,
             each_serializer: QuestionBankListSerializer,
             meta: pagination_meta(@pagy)
    end
  end
end
```

### API Response Shape

```json
{
  "question_banks": [ ... ],
  "meta": {
    "total_entries": 45,
    "per_page": 20,
    "current_page": 1,
    "total_pages": 3
  }
}
```

---

## Implementation Example: Web (HTML)

When responding to web requests, you use the exact same controller logic, but instead of rendering JSON, you render the view and use the `pagy_nav` helper.

```ruby
# app/controllers/question_banks_controller.rb
class QuestionBanksController < ApplicationController
  def index
    relation = QuestionBanksQuery.call(filters)

    # The exact same Pagy call as the API
    @pagy, @question_banks = pagy(relation, page: parse_page, limit: parse_per_page)
  end
end
```

### HTML View Rendering

Use `<%==` (note the double `==` to output raw HTML securely, as Pagy sanitizes it internally) to render the navigation links below your collection.

```erb
<h1>Question Banks</h1>

<div class="question-banks-list">
  <% @question_banks.each do |bank| %>
    <%= render partial: "bank", locals: { bank: bank } %>
  <% end %>
</div>

<div class="pagination-container">
  <%== pagy_nav(@pagy) %>
</div>
```

*(Note: Pagy supports Bootstrap, Tailwind, and Bulma out of the box via `pagy/extras`. If using a CSS framework, require the extra in `config/initializers/pagy.rb` and use `pagy_bootstrap_nav(@pagy)` or `pagy_nav_js` as appropriate.)*

---

## Spec Checklist

When testing paginated endpoints, ensure the following are covered:

- **Default Pagination:** Sending no `page` or `per_page` params returns page 1 with 20 items.
- **Hard Limit Enforcement:** Sending `per_page=500` successfully caps out at 100 items (does not crash or return 500 records).
- **API Responses:** The JSON response includes the `meta` key with `total_entries`, `per_page`, `current_page`, and `total_pages`.
- **HTML Responses:** The view correctly assigns `@pagy` and renders the navigation partial without throwing undefined method errors.
- **Query Optimization:** Ensure `Pagy` does not trigger an N+1 count query when evaluating complex Query Objects with `GROUP BY` statements.