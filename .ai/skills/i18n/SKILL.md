---
name: i18n
description: "English/Spanish translations and Mobility content translations. Use when adding user-facing text anywhere (views, components, operations, mailers), editing `config/locales/**`, or working with translatable models (Mobility table backend, original locale, approval status). Requires fully-qualified keys."
---

# I18n (English + Spanish)

Use this skill whenever code introduces or changes user-facing text. Keep the main body focused on mandatory rules and load the reference file for concrete examples.

## Quick Rules

Cite as `i18n R<n>`. Detail and examples follow below / in references/.

R1. **English and Spanish both.** Every new user-facing string is added to both `config/locales/en/` and `config/locales/es/`. → detail: Required Rules
R2. **Fully-qualified keys.** Call sites use full keys (`t("articles.index.title")`); no relative keys like `t(".title")`. → detail: references/i18n.md
R3. **Domain-based locale files.** Locale files are organized by domain under `config/locales/{en,es}/` (e.g. `articles.yml`, `components.yml`, `models.yml`). → detail: references/i18n.md
R4. **Key namespaces.** Components use `components.*`, operation messages `domain.operations.*`, domain errors `domain.errors.*`, contract wording `domain.forms.validation.*`. → detail: Key Conventions
R5. **No hardcoded text.** Flash, controller, operation and view messages come from translated keys, not string literals. → detail: Common Failure Modes
R6. **dry-schema via i18n backend.** `Dry::Schema.config.messages.backend = :i18n` is set, and shared predicate messages stay generic under `dry_schema.errors.*`. → detail: references/i18n.md
R7. **Contextual contract wording in rules.** Domain-specific validation copy uses explicit `rule(...)` failures with domain keys, not field-scoped `dry_schema.errors.rules.<field>`. → detail: references/i18n.md
R8. **I18n.l for dates.** Dates and times use `I18n.l`; no `strftime`. → detail: references/i18n.md
R9. **Number helpers.** Numbers and currency use `number_to_currency`, `number_with_delimiter`, etc.; no manual formatting. → detail: references/i18n.md
R10. **Model names via activerecord keys.** Model, attribute and enum labels live under `activerecord.models.*`, `activerecord.attributes.*`, `activerecord.enum.*`. → detail: Key Conventions
R11. **Mobility table backend.** Translatable models use `translates` with the `:table` backend and a `[model]_translations` table; no duplicated translated columns on the parent. → detail: references/mobility.md
R12. **Unique translation indexes.** Translation tables have a unique index on `[:model_id, :locale]`. → detail: references/mobility.md
R13. **Original locale on parent.** `original_locale` is stored on the parent record; `is_approved` lives on translation rows. → detail: references/mobility.md
R14. **Pure Mobility accessors.** Use `article.title` and metadata methods like `approved?`; no `display_*` wrappers or custom model fallbacks (use app-level I18n fallbacks). → detail: references/mobility.md

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
