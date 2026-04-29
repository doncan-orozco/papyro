# Backend Anti-Patterns: Presentation and I18n

## Views

Avoid:
- missing `turbo_frame_tag` wrappers for frame responses
- hardcoded strings in Phlex views
- relative translation keys like `t(".title")`

Prefer fully-qualified keys and domain-shaped frame responses.

```ruby
class Views::Articles::Show < Views::Base
  def view_template
    turbo_frame_tag "article_details" do
      h1 { t("articles.show.title") }
    end
  end
end
```

## Components

Avoid:
- components without `**attrs` support
- nested UI button components inside compound trigger helpers
- child `.new` calls in views for compound components

Prefer:
- `initialize(**attrs)` on parent and nested child classes
- trigger helpers like `dropdown.trigger { ... }`
- merged caller `data:` hashes instead of overwriting them

## Date, Time, and Numbers

Avoid:
- `strftime`
- manual currency formatting like `"$#{amount}"`
- delimiter logic written by hand

Prefer:
- `I18n.l(timestamp, format: :long)`
- `number_to_currency(total)`
- `number_with_delimiter(count)`

## Translation Keys

Avoid:
- domain-agnostic error keys reused across unrelated contracts
- operation messages mixed into general domain error namespaces
- hardcoded user-facing copy in controllers, mailers, or jobs

Prefer:
- `domain.view.action.key`
- `domain.operations.create.success`
- `domain.errors.specific_condition`
- `components.ui.button.submit`
