---
name: jobs-and-mailers
description: "Background jobs, mailers and external clients in Papyro. Use when creating or editing files in `app/jobs/**`, `app/mailers/**`, mailer views (`app/views/*_mailer/**`) or `app/services/**` (e.g. GeminiClient), in the host or the papyro_studio engine. Covers thin job shells delegating to operations, idempotency, Solid Queue, mailer i18n and presenters, and injected external clients with timeouts."
---

# Jobs, Mailers and External Clients (Papyro)

## Quick Rules
Cite as `jobs-and-mailers R<n>`. Detail and examples follow below.

R1. **Thin jobs.** A job parses its arguments, calls ONE operation (or query + per-item operation for sweepers), and returns; no business rules, no multi-step workflows in `perform`. → detail: Jobs
R2. **Queries belong to query objects.** Selection logic (`where/joins`) in a job moves to `app/concepts/*/query/` (`query-object-pattern`); the job iterates with `find_each`. → detail: Jobs
R3. **Pass ids, not records.** Enqueue primitives (ids, locale strings); reload inside `perform`; `discard_on ActiveRecord::RecordNotFound` (or `ActiveJob::DeserializationError`) when the record may vanish. → detail: Jobs
R4. **Idempotent and retry-safe.** Running a job twice must be harmless (check state before acting, unique slot/dedupe key, no double-create); declare `retry_on`/`discard_on` deliberately. → detail: Jobs
R5. **Enqueue after commit.** Never enqueue from inside a transaction; enqueue after it commits (`after_commit` is NOT a place for orchestration; do it in the operation after the transaction). → detail: Jobs
R6. **Per-item isolation.** Sweepers rescue and log per item so one failure does not abort the batch; they never swallow errors silently. → detail: Jobs
R7. **Named queues.** Jobs declare `queue_as` (`:default`, `:maintenance`, …) matching the Solid Queue configuration. → detail: Jobs
R8. **No authorization or `Current` in jobs.** Pass the actor/locale explicitly as arguments; jobs run outside a request. → detail: Jobs
R9. **Mailers are thin.** A mailer method assigns what its view needs and calls `mail`; subject and body copy come from fully-qualified `t("…")` keys with EN + ES entries. → detail: Mailers
R10. **Presenter-fed mail views.** Display decisions for a mail (copy selection, formatting) live in a presenter assigned as `@presenter`; `.html.erb` and `.text.erb` stay dumb and mirror each other. → detail: Mailers
R11. **Locale-explicit mail.** Deliver in the recipient's locale (`I18n.with_locale(recipient_locale)`), never the sender's request locale. → detail: Mailers
R12. **Deliver later.** Controllers/operations use `deliver_later`; no network work inside a request. → detail: Mailers
R13. **Injected external clients.** External APIs (e.g. `GeminiClient`) are plain objects with the API key and base URL injectable, explicit open/read timeouts, and no domain logic; callers pass them in or construct them at the operation boundary. → detail: External clients
R14. **Failures are explicit.** A client never returns `nil` for every failure silently; it logs context-rich errors (no secrets/PII) and returns a result the caller can route on (or raises a typed error). → detail: External clients
R15. **No network I/O inside a DB transaction.** Call external services before or after the transaction (SQLite has a single writer). → detail: External clients

## Jobs
Existing shape: `Articles::EmptyTrashJob`, `CleanupEmptyDraftsJob`, `Articles::GenerateOgImageJob`. Some predate these rules (selection SQL inside `perform`); treat them as PRE_EXISTING_DEBT unless the change touches them, in which case apply R1-R2. Solid Queue runs on SQLite; mission control is mounted at `/jobs`.

## Mailers
`ApplicationMailer` sets the default sender and layout. Views live in `app/views/<name>_mailer/{action}.html.erb|text.erb`. Keys are fully qualified (`passwords_mailer.reset.subject`), never relative.

## External clients
`app/services/` holds only clients for outside systems. Domain services live in `app/concepts/*/service/` (e.g. `Articles::Service::ContentAnalysis`), and writes belong to operations. `GeminiClient` already sets timeouts; its blanket `rescue StandardError` returning `nil` is the pattern R14 asks callers to improve when touched.

## Repos
The engine (`papyro_studio`) has `app/jobs/papyro_studio/application_job.rb` and `app/mailers/papyro_studio/`; the same rules apply. Locale keys for mails/UI strings live in the host.

## Related
`../operation-pattern/SKILL.md`, `../query-object-pattern/SKILL.md`, `../i18n/SKILL.md`, `../presenter-pattern/SKILL.md`, `../testing/SKILL.md`.
