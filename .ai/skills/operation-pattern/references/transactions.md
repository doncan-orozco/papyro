# Transactions in Multi-Write Operations


If an operation performs more than one write, or if a partial write would leave the domain in an invalid split state, wrap the workflow in a transaction.

Typical triggers:
- update settings + publish state in one command
- save a model + save a related translation
- persist a record + enqueue durable side effects that depend on that write

Canonical pattern:

```ruby
def call(model:, settings_params: {}, locale: I18n.locale)
  persisted_model = step publish_with_optional_settings(
    model: model,
    settings_params: settings_params,
    locale: locale
  )

  { model: persisted_model }
end

def publish_with_optional_settings(model:, settings_params:, locale:)
  transaction_failure = nil
  preserved_failure = nil

  persisted_model = Mobility.with_locale(locale) do
    ActiveRecord::Base.transaction do
      prepared_model = if settings_params.present?
        result = apply_settings(model: model, settings_params: settings_params, locale: locale)
        unless result.success?
          transaction_failure = result
          raise ActiveRecord::Rollback
        end

        result.value!
      else
        model
      end

      publishable_model = validate_publishable(prepared_model)
      unless publishable_model.success?
        if publishable_model.failure[:code] == :already_published
          preserved_failure = publishable_model
          prepared_model
        else
          transaction_failure = publishable_model
          raise ActiveRecord::Rollback
        end
      else
        persisted_model = persist_publish_state(publishable_model.value!)
        unless persisted_model.success?
          transaction_failure = persisted_model
          raise ActiveRecord::Rollback
        end

        persisted_model.value!
      end
    end
  end

  return transaction_failure if transaction_failure
  return preserved_failure if preserved_failure

  Success(persisted_model)
end
```

If there is only one `save`, rely on the transaction Active Record already wraps around that single persistence call.
Use the `preserved_failure` branch only when the business rule explicitly allows metadata changes to persist while rejecting the state transition. All other failures should roll back.
