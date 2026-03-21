# frozen_string_literal: true

# Reform uses dry-validation as the default backend for all forms.
Rails.application.config.reform.validations = :dry
Rails.application.config.reform.enable_active_model_builder_methods = true

# Use Rails I18n backend for dry-schema predicate messages so all error
# messages live in config/locales under dry_schema.errors.*
Dry::Schema.config.messages.backend = :i18n
