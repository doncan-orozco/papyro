---
name: current-context
description: Implementation of ActiveSupport::CurrentAttributes for managing request-scoped state. Use to eliminate prop-drilling of current_user and current_locale across models, views, and services.
---

# Rails Request Context (Current)

## 1. The Singleton Pattern
- Define a `Current` model inheriting from `ActiveSupport::CurrentAttributes`.
- Attributes are automatically reset after every request to prevent data leakage.

## 2. Global Accessibility
- **Views/Phlex**: Access `Current.user` without passing it as a prop.
- **Models**: Use `Current.user` in callbacks (e.g., for auditing `updated_by`).
- **Services**: Pull `Current.locale` to format localized strings or currency.

## 3. Integration Standards
- **Syncing**: Always sync `I18n.locale` and `Time.zone` with `Current` attributes in the `ApplicationController`.
- **Testing**: In unit tests, manually assign `Current.user = users(:admin)` to simulate the request context.
- **Auditing**: Excellent for "Whodunnit" patterns in activity logs.

```ruby
# Example Audit log in a model
after_create { AuditLog.create(record: self, user: Current.user) }