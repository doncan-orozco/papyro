# Flash and Toast Test Examples

Flash messages render through `Components::Shared::Flash`, which mounts one Chadcn Sonner Toaster (`section#toaster`) and emits one `<template data-chadcn--sonner-toast>` per message. The Sonner Stimulus controller turns the templates into visible `li[data-sonner-toast]` items in the browser.

## Integration Tests (Controller Flash)

Assert the toast template and its description part in the response HTML:

```ruby
# test/controllers/articles_controller_test.rb
test "create action redirects with success flash" do
  post articles_path, params: { article: valid_params }

  assert_redirected_to article_path(@article)
  follow_redirect!

  assert_select "template[data-chadcn--sonner-toast][data-type=success] [data-description]",
    /#{Regexp.escape(I18n.t("articles.operations.create.success"))}/
end

test "create action with invalid data shows error flash" do
  post articles_path, params: { article: invalid_params }

  assert_response :unprocessable_entity
  assert_select "template[data-chadcn--sonner-toast][data-type=error]"
end
```

## Component Unit Tests

Render the Flash component and inspect the Toaster markup:

```ruby
# test/components/shared/flash_test.rb
test "renders a notice as a success toast with the localized title" do
  html = Nokogiri::HTML5.fragment(
    ApplicationController.render(Components::Shared::Flash.new(flash: { notice: "Article saved" }), layout: false)
  )
  toast = html.css("template[data-chadcn--sonner-toast]").sole

  assert_equal "success", toast["data-type"]
  assert_equal I18n.t("app.toasts.success"), toast.at_css("[data-title]").text
  assert_equal "Article saved", toast.at_css("[data-description]").text
end
```

## System Tests (Full User Flow)

Verify toast visibility in the rendered page (JS builds `li[data-sonner-toast]` inside `#toaster`):

```ruby
# test/system/articles/create_article_flow_test.rb
test "user sees success toast after creating article" do
  visit new_article_path
  fill_in "Title", with: "New Article"
  click_button "Create"

  assert_current_path article_path(Article.last)
  assert_selector "#toaster li[data-sonner-toast]", text: I18n.t("articles.operations.create.success")
end
```

**Key assertions for toast testing**:
- Controller/component tests: `template[data-chadcn--sonner-toast]` with `data-type` (`success` or `error`) and its `[data-title]` / `[data-description]` parts.
- System tests: `#toaster li[data-sonner-toast]` for what the user actually sees.
- The Toaster is a polite live region (`aria-live="polite"`); assert it when changing the Toaster itself.
