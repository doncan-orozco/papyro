---
name: controller
description: "Golden archetype for Rails controllers in Papyro. Use when creating, editing, reviewing or refactoring any file in `app/controllers/` or `config/routes.rb`, or when handling operation results, Pundit authorization, pagination (Pagy), Turbo Stream responses, RESTful extraction of custom actions, or content-vs-interface locale in controllers. Single source of truth for controller guidance."
---

# Golden Controller Skill (Papyro)

Controllers are the **HTTP boundary only**: parse params, authorize, dispatch one Query (read) or Operation (write), then redirect/render. They are NOT for queries, business logic, display logic, or HTML generation. For workflows in `app/concepts/*/operation/` pair with `../operation-pattern/SKILL.md`.

## Quick Rules

Cite as `controller R<n>`. Detail and examples follow below / in references/.

All rules are mandatory.

R1. **Strict REST.** Only `index show new create edit update destroy`; no custom verbs (`publish`, `restore`, `purge`). Transitions are sub-resource controllers (`PublicationsController#create`). → detail: references/restful-refactoring.md, references/routing-and-sessions.md
R2. **No business logic or state guard clauses.** Never check `@article.trashed?` etc. in the controller; the Operation validates state and returns a failure.
R3. **No view helpers in controllers.** No tab parsing, URL builders or badge logic; pass raw `params` to the Phlex view. Build a presenter once, assign `@presenter` once, and reuse it for layout and view.
R4. **Content locale vs. interface locale.** Where a content locale is in play (Studio controllers via `studio_content_locale`, or any action that takes an explicit `content_locale` param), wrap Operations and content renders in `Mobility.with_locale(content_locale)`; public host controllers that render in the UI locale need no wrapper. Never wrap actions in `I18n.with_locale` (it flips flash/UI language); UI locale is set globally via `around_action`.
R5. **Lean base controllers.** `ApplicationController` and `*::BaseController` hold only `layout`, `rescue_from`, and `include`. Feature logic goes in `app/controllers/concerns/`.
R6. **Authorize at the boundary.** Pundit `authorize` before any Operation; `policy_scope`/`skip_policy_scope` on `index`. Never authorize inside Operations. Find the record once in the controller and pass `model:` to the Operation.
R7. **Handle both result branches.** `result.value!` only in the success branch, `result.failure` only in the else; never `result[:model]`. Invalid model ⇒ `render … status: :unprocessable_entity`, never redirect. → detail: references/result-handling.md
R8. **One operation per action.** One user action dispatches ONE Operation; route outcomes on `failure[:code]`, do not chain sibling operations in the controller. → detail: references/result-handling.md
R9. **Pagination lives in the controller.** Query Objects return unpaginated relations; `parse_page`/`parse_per_page` live in `ApplicationController`. See [references/pagination.md](references/pagination.md).
R10. **I18n.** Fully-qualified `t("studio.articles.operations.create.success")` keys, never relative (`t(".x")`) or hardcoded strings; add English and Spanish.
R11. **No HTML generation.** No `view_context.tag` or inline markup, including Turbo Streams. Render a Phlex component or dedicated template.

## Minimal shape

```ruby
def update
  authorize article, policy_class: Studio::ArticlePolicy
  # Studio controller: content_locale = studio_content_locale(default: article.original_locale)
  result = Mobility.with_locale(content_locale) do
    Articles::Operation::Update.new.call(model: article, params: article_params.to_h, locale: content_locale)
  end

  if result.success?
    redirect_to studio_articles_path, notice: t("studio.articles.operations.update.success")
  else
    render Views::Studio::Articles::Edit.new(article: result.failure[:model]), status: :unprocessable_entity
  end
end
```

Full RESTful, Turbo Stream and sub-resource templates: [references/templates.md](references/templates.md).

## Verification Checklist

- [ ] Only the 7 REST actions; transitions extracted to sub-resource controllers
- [ ] No state checks, view helpers, or HTML generation
- [ ] Reads via Query Objects, writes via Operations
- [ ] `Mobility.with_locale` for content locale, never `I18n.with_locale` in actions
- [ ] Pundit before operation; no double record lookup
- [ ] Result branches handled; failures render with `:unprocessable_entity`
- [ ] Turbo Stream renders a dedicated view artifact
- [ ] Qualified `t("...")` keys in EN and ES
- [ ] Pagination in controller; base controller lean

## Related Skills

`../operation-pattern`, `../query-object-pattern`, `../pundit-auth`, `../phlex-view-pattern` (Turbo Frames/Streams), `../i18n`.
