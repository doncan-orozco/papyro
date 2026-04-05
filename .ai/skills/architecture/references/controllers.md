# Controller Examples

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#controllers)**

Controllers are thin - they only receive requests, call Operations, and return responses. Trailblazer Operations return `Trailblazer::Operation::Result` objects (use `result.success?` / `result.failure?`).

## ApplicationController Composition Rule

`ApplicationController` should compose cross-cutting concerns, not own feature-specific implementations.

✅ Prefer:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication
  include LocaleManagement

  allow_browser versions: :modern
  stale_when_importmap_changes
end
```

```ruby
# app/controllers/concerns/locale_management.rb
module LocaleManagement
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_locale
  end

  private

  def set_locale
    I18n.locale = requested_locale || I18n.default_locale
  end
end
```

❌ Avoid placing full feature stacks (`before_action`, parsing helpers, persistence logic) directly in `ApplicationController`.

## Task Requirements

Task requirements live in the checklist:
- [Task and issue requirements](../VERIFICATION_CHECKLIST.md#taskissue-requirements)

## Basic CRUD Controller

```ruby
# app/controllers/game/moves_controller.rb
class Game::MovesController < ApplicationController
  def create
    result = Game::Operation::MovePlayer.call(
      params: params.to_unsafe_h,
      current_user: current_user
    )

    if result.success?
      # Broadcast happens inside the Operation
      head :ok
    else
      error_key = result[:error_key]
      case error_key
      when :invalid_move
        render json: { error: result[:error] }, status: :unprocessable_entity
      when :unauthorized
        head :forbidden
      else
        head :internal_server_error
      end
    end
  end
end
```

See [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#controllers) for complete controller guidelines.
