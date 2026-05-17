---
name: i18n
description: Internationalization patterns for English and Spanish translations. Use when adding new views, components, operations, or any user-facing text. Covers fully-qualified translation keys, file structure, view keys, component keys, operation/contract keys, model keys, and mailer translations.
---

# I18n (English + Spanish)

Use this skill whenever code introduces or changes user-facing text. Keep the main body focused on mandatory rules and load the reference file for concrete examples.

## Required Rules

- Add translations in both English and Spanish.
- Keep locale files domain-based under `config/locales/{en,es}/`.
- Use fully-qualified translation keys; do not use relative keys like `t(".title")`.
- Keep component keys under `components.*`, operation messages under `domain.operations.*`, and domain-specific error wording under `domain.errors.*` or `domain.forms.validation.*`.
- Configure dry-schema predicate messages through `Dry::Schema.config.messages.backend = :i18n`.
- Keep shared predicate defaults generic in `dry_schema.errors.*`.
- Put contextual contract wording in explicit `rule(...)` failures with domain keys.
- Use `I18n.l` for dates and times; do not use `strftime`.
- Use Rails number helpers such as `number_to_currency` and `number_with_delimiter`; do not format numbers manually.

## Fast Workflow

1. Identify the text surface: view, component, operation, contract, model, mailer, or shared app copy.
2. Place the key in the appropriate domain locale file for both `en` and `es`.
3. Use a fully-qualified key at the call site.
4. If validation is involved, keep predicate defaults generic and use explicit contract rule keys for domain wording.
5. Recheck the key structure against [../../copilot-instructions.md](/.github/copilot-instructions.md#-internationalization-i18n).

## Key Conventions

- Views: `articles.index.title`
- Components: `components.ui.button.submit`
- Operations: `articles.operations.create.success`
- Contract or form wording: `articles.forms.validation.slug_invalid_format`
- Domain errors: `articles.errors.not_found`
- Models and enums: `activerecord.models.article`, `activerecord.attributes.article.title`

## Reference Map

- **[references/i18n.md](references/i18n.md)**
  Use for full examples covering views, components, operation messages, dry-schema integration, model attributes, date/time formatting, currency helpers, pluralization, and interpolation.

## Common Failure Modes

- Relative keys that become fragile when views move
- Shared `dry_schema.errors.rules.<field>` messages that collide across forms using the same field names
- Flash or controller errors built from hardcoded strings instead of translated keys
- Dates, times, or currency manually formatted in Ruby code

See [references/i18n.md](references/i18n.md) for examples and [../../copilot-instructions.md](/.github/copilot-instructions.md#-internationalization-i18n) for enforcement rules.
