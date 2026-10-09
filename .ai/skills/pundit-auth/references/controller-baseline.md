# ApplicationController Baseline

## ApplicationController Baseline

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_pundit_authorization

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  private

  def verify_pundit_authorization
    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end

  def pundit_user
    Current.user
  end

  def handle_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    message = I18n.t("#{policy_name}.#{exception.query}", scope: "pundit", default: I18n.t("admin.errors.unauthorized"))

    redirect_to(request.referrer || root_path, alert: message)
  end

  def handle_not_found
    skip_authorization unless pundit_policy_authorized?
    skip_policy_scope unless pundit_policy_scoped?
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
```

Notes:
- Use `pundit_user` when your app does not expose `current_user` (Rails 8 generator uses `Current.user`).
- If your app switches users in-session, call `pundit_reset!` after switching.
- `handle_not_found` guards Pundit verification with `pundit_policy_authorized?` / `pundit_policy_scoped?` so the `after_action` hook does not raise a second error.

## Overriding Not-Found Behaviour per Namespace

When a bounded-context namespace needs different not-found behaviour (e.g., Studio redirects to the creator's list instead of rendering 404.html), override `handle_not_found` in the namespace base controller:

```ruby
# app/controllers/studio/base_controller.rb
module Studio
  class BaseController < ApplicationController
    private

    def handle_not_found
      skip_authorization unless pundit_policy_authorized?
      skip_policy_scope unless pundit_policy_scoped?
      redirect_to studio_articles_path, alert: t("articles.errors.not_found")
    end
  end
end
```

All Studio controllers inherit this redirect automatically. No inline rescue blocks needed in any child controller.
