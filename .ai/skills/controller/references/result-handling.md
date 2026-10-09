# Operation Result Handling Details

## Failure-Code Router Pattern

Controllers should route outcomes, not explain them.

```ruby
def create
  content_locale = studio_content_locale(default: studio_article.original_locale)

  result = Mobility.with_locale(content_locale) do
    Articles::Operation::Publish.new.call(
      model: studio_article,
      settings_params: publish_settings_params_for_create,
      locale: content_locale
    )
  end

  if result.success?
    handle_successful_publish
  else
    handle_failed_publish(failure: result.failure, content_locale: content_locale)
  end
end

def publish_settings_params_for_create
  return {} unless params[:article].present?

  publish_settings_params.to_h
end

def handle_failed_publish(failure:, content_locale:)
  case failure[:code]
  when :already_published
    redirect_to edit_studio_article_path(studio_article.uuid), notice: t("studio.articles.operations.update.success")
  when :trashed
    redirect_to edit_studio_article_path(studio_article.uuid), alert: failure[:message]
  else
    Mobility.with_locale(content_locale) do
      render Views::Studio::Articles::Edit.new(article: failure[:model] || studio_article, content_locale: content_locale),
        status: :unprocessable_entity
    end
  end
end
```

The controller does not decide whether publish requires a settings update first. That orchestration belongs in the operation.
