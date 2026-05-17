# Presenter Base Inheritance and Route Helpers (Papyro)

## Problem

A common mistake is to create a new presenter (e.g., `Studio::Articles::Presenter::Editor < ApplicationPresenter`) and assume a project-wide `ApplicationPresenter` exists. In Papyro, the correct base class is `Core::Presenter::Base`.

## Solution

- **Always inherit presenters from `Core::Presenter::Base`**
- This base class provides:
  - `SimpleDelegator` wrapping
  - Shared presenter logic
  - A `helpers` method for Rails route helpers

## Example

```ruby
module Studio
  module Articles
    module Presenter
      class Editor < ::Core::Presenter::Base
        # ...
      end
    end
  end
end
```

## Route Helpers in Presenters

- Use the `helpers` method provided by `Core::Presenter::Base` to access Rails route helpers:

```ruby
def form_url
  helpers.studio_article_path(article.uuid, content_locale: content_locale)
end
```

## Do NOT

- Do **not** inherit from `ApplicationPresenter` (does not exist)
- Do **not** use `include Rails.application.routes.url_helpers` in each presenter
- Do **not** access route helpers via global scope in presenters

## Checklist
- [x] All presenters inherit from `Core::Presenter::Base`
- [x] Use `helpers` for route/path helpers
- [x] No `ApplicationPresenter` references
- [x] No direct `include Rails.application.routes.url_helpers` in presenters

---

_Last updated: 2026-05-14_
