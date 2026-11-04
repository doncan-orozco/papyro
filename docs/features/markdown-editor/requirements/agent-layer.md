# AGENT: Agent layer requirements for the Md gem

The agent layer is the optional fourth layer of the Md gem, after the render core, the viewer and the editor. It lets an AI
agent read a markdown document and propose changes as exact-string patches against the revision it read. A human then
accepts or rejects those changes hunk by hunk, and provenance is recorded on everything that lands. The layer can also
expose the same operations to external agents through MCP, and it lets an app plug in its own LLM calls without the gem
depending on any vendor. Agents are the reason the gem stores markdown byte for byte: the benchmark chose a
source-of-truth editor so that the bytes an agent reads are the bytes the writer saved (benchmark report, "Source-of-truth
libraries beat doc-model editors"). This layer is where that choice pays off. It is also where the gem can do harm, because a
document is an injection vector and an agent edit that renders before approval is an exfiltration channel.

## Scope

This doc decides:

- the split between the gem and the host app for agent features;
- the patch contract (request, response, error cases) and how concurrent human and agent edits are reconciled;
- the suggestion, hunk and revision data model that the gem's generator installs, and the provenance fields;
- the review UI contract, including what it neutralises in pending agent text;
- the authorization hook, rate limiting and the audit signal;
- the optional MCP tools (names, scopes, annotations), built on the official `mcp` gem;
- markdown twins of records (Rails 8.1 `format.md`), the read path for agents that do not speak MCP;
- the extension point where an app calls its own LLM.

It leaves the following to other areas:

- the render pipeline and sanitizer (render-and-viewer.md, area RENDER);
- the editor surface, autosave and its conflict banner (editor-ux.md, area EDIT);
- install and configuration conventions (developer-experience.md, area DX);
- Active Record, Action Cable and Turbo integration details (rails-framework-integration.md, area RAILS);
- Papyro's own use (papyro-as-consumer.md, area PAPYRO).

Out of scope (WON'T, for the 0.x and 1.0 releases):

- An LLM client, prompt templates, model selection or a chat UI. The gem never calls a model (benchmark design rule 4).
- Inline ghost-text autocomplete. It is an editor feature with a different contract (no review step) and is left to a later EDIT decision.
- Real-time co-editing (CRDT, Yjs). The benchmark keeps optimistic locking now and adds Yjs "only if demanded".
- Paragraph-anchored comments, by humans or agents. They are Phase 3 of the benchmark roadmap, and the hunk model here does not block them.
- An OAuth authorization server or token issuance. The gem acts only as a resource server and leaves tokens to the app.
- `/llms.txt`, publishing, scheduling and any other editorial workflow. Those are host concerns (benchmark, "What stays in Papyro").
- C2PA text manifests and reader-facing AI disclosure badges. C2PA for text is not dependable yet (research note §4).
- Authorship shading of accepted agent text in the editor (iA Writer style). It could come later, built on the provenance columns defined here.

## Questions

1. Which parts of the agent layer belong in the gem and which in the host app?
2. How are concurrent human and agent edits reconciled?
3. Which prompt-injection and exfiltration cases must the review UI neutralise?
4. What is the patch contract, as a JSON example with its error cases?
5. Which MCP tools does the gem offer, with which scopes and annotations?
6. How does an app plug its own LLM calls in without the gem depending on a vendor?
7. What does the gem offer for markdown twins of pages, given what Rails 8.1 ships for markdown responses?
8. What does each of these cost a developer who adds the gem to a new app?

## Findings

### What the benchmark already settles

The benchmark report and the agents research note settle the direction, so this doc does not research it again:

- **AI edits are proposals, not commits.** TipTap's AI Toolkit, Word's Copilot Agent Mode and Liveblocks all show agent
  edits as suggestions that a human accepts. Word's agent "cannot … accept/reject tracked changes" (research note §1).
- **Review happens per hunk, not per session.** When Cursor moved to session-level review, users complained that they
  wanted "file by file, chunk by chunk" control (benchmark, "Agents get exact-string patches…").
- **Exact-string patches are the agent-friendly write shape.** Notion's markdown endpoint uses `old_str`/`new_str`, the
  same shape as coding agents' edit tools. An ambiguous match fails safely, and concurrent edits do not shift addresses
  the way they shift line numbers (research note §2).
- **Optimistic locking is the concurrency baseline.** Google Docs' `requiredRevisionId` fails a write when the document
  has changed, and Confluence servers require the current version number (research note §2).
- **Provenance lives in the database, not in the markdown.** iA Writer keeps authorship metadata inside the file, where
  edits in other apps misplace it and export strips it (research note §4).
- **Pending means pending.** Notion AI saved edits before approval, so an injected image URL leaked data whether or not
  the user rejected the edit (PromptArmor). The mitigations are a true pending state, inert remote URLs, scoped tokens,
  rate limits and an audit log (benchmark, "Agents get exact-string patches…").
- **The official `mcp` gem is the transport.** It reached 1.0.0 on 2026-07-27 and implements MCP 2025-06-18 and
  2025-11-25. A controller-based integration fits a Rails dev loop better than mounting it at boot (benchmark, same section).
- **The gem defines the contract and never calls an LLM.** Authorization goes through a hook that the app supplies
  (benchmark, "What the gem provides", design rule 4).

### Patch contracts in the field

| System | Addressing | Multiple matches | No match | Concurrency | Atomicity |
|---|---|---|---|---|---|
| Notion `update_content` | `old_str`/`new_str`, up to 100 per request, `old_str` at least 1 character | `validation_error` unless `replace_all_matches` | a `warnings` entry; the request fails only when no content-changing operation matches | generic 409 `conflict_error` | partial: matching operations apply, misses become warnings |
| Google Docs `batchUpdate` | index ranges | n/a | n/a | `requiredRevisionId` fails on change; `targetRevisionId` merges | all or nothing per batch |
| Confluence (community MCP servers) | whole page in a chosen format | n/a | n/a | current `version` number required | whole page |
| Sanity Agent Actions `patch` | schema paths | n/a | n/a | n/v | `noWrite: true` dry run; never writes published documents by default |

Notion's partial semantics save a round trip, but the reviewer can end up with a suggestion the agent did not fully
intend. A review queue is easier to reason about when each call is all or nothing and returns a per-edit error list.
Either the whole proposal is stored as the agent meant it, or nothing is stored and the agent retries with the errors in
hand. Notion also refuses an empty `old_str`, so every insert has to anchor on neighbouring text. The gem should do the
same, because an insert without an anchor has no position that survives concurrent edits. The one exception is an empty
base text, where an insert has only one possible position.

### Review UI building blocks

`@codemirror/merge` 6.12.3 is MIT-licensed and belongs to the same library family as the editor area's choice. Its
`unifiedMergeView` takes these options:

- `mergeControls`: accept and reject buttons on each changed chunk, which a render function can replace;
- `collapseUnchanged` and `allowInlineDiffs`.

The package also exports these functions:

- the commands `acceptChunk(view, pos)` and `rejectChunk(view, pos)`, and `getChunks(state)`;
- `presentableDiff`, which aligns changes to word boundaries for display.

Its chunks come from a diff between the original and the edited document, so they do not always match the edits an agent
sent: two nearby edits can merge into one chunk, and one edit can split into several. The unit of review therefore has to
be the agent's edit, which this doc calls a hunk, and the diff only displays the change inside it. A hunk list rendered on
the server works in every app, with or without the editor and with or without JavaScript. Apps that also use the gem's
editor get the merge view as an enhancement.

### Attack cases the review must neutralise

Prompt injection has no complete fix: OWASP ranks it first in its LLM Top 10 and says it is unclear whether fool-proof
prevention exists. The layer cannot stop a model from being steered. What it can do is limit what an injected model
achieves. Nothing the model writes takes effect, renders a remote resource or leaves the server before a human accepts
it. The known cases follow:

| # | Case | Observed in | Neutralisation in the review UI |
|---|---|---|---|
| 1 | Markdown image whose URL carries private data; the browser fetches it on render | Notion AI (PromptArmor), Claude, Azure AI Playground, Vertex AI, Cline (Embrace The Red), HuggingChat (PromptArmor) | Images added by a pending suggestion render as a placeholder that shows the URL as text, and no request is made. Claude's fix used the same idea: an image loads only after the user clicks "Show Image". |
| 2 | Link whose query string carries data, waiting for a click | ChatGPT plugin exfiltration variants (Embrace The Red) | New or changed link destinations render as non-clickable text that shows the full URL with the host highlighted |
| 3 | Same visible link text, new destination | design inference | The hunk shows destination changes explicitly, not only the visible text diff |
| 4 | Reference-style definitions and autolinks (`[x]: https://…`, bare URLs) that would become embed cards | design inference | Same treatment as cases 1 and 2, applied on the parsed AST rather than by regex; no oEmbed or unfurl fetch while the suggestion is pending |
| 5 | Raw HTML (`img`, `iframe`, `form`) and `javascript:`/`data:` URLs | benchmark, XSS section | Scrubbed by the render core (area RENDER); the review shows it as literal source text with a warning badge |
| 6 | Hidden instructions or payloads: HTML comments, zero-width characters, Unicode tag characters, bidi overrides | Notion's white-on-white text (PromptArmor); bidi reordering hides text from reviewers (Trojan Source, CVE-2021-42574) | Invisible characters appear as visible badges in the hunk, and HTML comments appear as source. Agent edits containing bidi controls or tag characters are refused. |
| 7 | Lookalike hosts | design inference | Hosts that contain non-ASCII characters are shown in their punycode form |
| 8 | The agent's own rationale used as a channel | design inference | The rationale renders as plain text, never as markdown, so it carries no links or images |
| 9 | Mass deletion, or a flood of suggestions that buries real work | Notion's `allow_deleting_content: false` guard | A hunk that deletes more than a configured share of the document is flagged, and pending suggestions per actor and document are capped |

The server follows the same rule: while a suggestion is pending, the gem makes no outbound request for it, whether an
image dimension probe, an embed fetch or a link check. The gem's MCP tools fetch no URL and send nothing anywhere. That
removes the exfiltration leg of Willison's "lethal trifecta" from the gem's own surface. The MCP specification asks the
same of servers: they "MUST" validate all tool inputs, implement access controls, rate limit tool invocations and
sanitize tool outputs.

### MCP with the official gem

The `mcp` gem's documentation confirms the pieces this layer needs:

- **Tools** subclass `MCP::Tool` and declare `description`, `input_schema`, `output_schema` and
  `annotations(read_only_hint:, destructive_hint:, idempotent_hint:, open_world_hint:, title:)`. They receive
  `server_context:` in `call`. A tool reports a business error with `MCP::Tool::Response.new(…, error: true)`, which
  reaches the client as `isError: true`. The specification separates these tool execution errors, which the model can
  read and correct, from JSON-RPC protocol errors.
- **Transport.** `MCP::Server::Transports::StreamableHTTPTransport` is a Rack app. When it is mounted once at boot it keeps
  session and SSE state in memory and "must run in a single process". The documented Rails controller pattern instead
  builds a new server for each request with `stateless: true` and calls `transport.handle_request(request)`. That avoids
  both the reload problem the benchmark flagged and the single-process limit. The cost is losing server-to-client
  notifications, which these tools do not need.
- **Authorization.** The gem acts only as an OAuth 2.1 resource server. Its main pieces:
  - Token verification: `MCP::Server::OAuth::JWTVerifier`, `IntrospectionVerifier`, or any object with `verify(token)`.
  - `ProtectedResourceMetadata` serves the RFC 9728 metadata document.
  - Scope checks: `required_scopes:` on the transport, and `server_context.require_scopes!("…")` inside a tool.
  - The verified token reaches tools as `server_context.auth_info` (subject, client id, scopes, audience). Without bearer
    authentication `require_scopes!` "fails closed".
- **Specification rules that bind the design:**
  - Authorization is optional. Stdio servers take credentials from the environment instead.
  - A missing scope gets a 403 with `error="insufficient_scope"` and the required scopes.
  - Servers must validate the token audience and must not pass tokens through.
  - Tool annotations are hints that clients "MUST consider … untrusted unless they come from trusted servers", so an
    annotation never replaces a scope check on the server.
  - Tool names may contain dots. As a design inference, the gem uses an `md_` prefix instead, because some clients
    forward tool names to model APIs whose function-name rules are stricter than MCP's, and an underscore name is valid
    everywhere.

### Rails pieces the layer builds on

- **Markdown responses.** Rails 8.1 adds markdown rendering: `format.md { render markdown: @page }` in a `respond_to`
  block, which calls the object's `to_markdown` for the body, much as `to_json` works. Third-party write-ups say it serves
  both `.md` URLs and `Accept: text/markdown`. The RAILS area spike should check whether routes need `format: true` for the
  suffix and how Rails treats a browser's `Accept` header. A twin served by content negotiation needs `Vary: Accept` so
  that caches keep the two representations apart.
- **Rate limiting.** `rate_limit(to:, within:, by:, with:, store:, name:, scope:)` raises
  `ActionController::TooManyRequests`, which Rails answers with a 429. The default handler sets no `Retry-After` and no
  body, so the gem supplies its own `with:`. `by:` can key on the token subject instead of the
  IP, and `name:` separates read and write budgets in one controller.
- **Optimistic locking.** Active Record's `lock_version` raises `ActiveRecord::StaleObjectError` on a concurrent update.
  It guards the final write of an accepted suggestion the same way it guards an editor save.
- **Line endings.** Browsers are expected to submit textarea line breaks as CRLF (not verified for this doc; the editor
  area's textarea sync must confirm it), while agents read and send LF. If stored text keeps CRLF, an `old_str` an agent
  copied from an LF rendering never matches. The layer must normalise text to LF before it computes revisions or matches
  edits.

### Answer: what belongs in the gem and what in the host app

| Concern | Gem (agent layer) | Host app |
|---|---|---|
| Patch contract, matching, validation, rebase | `Md::Patch`, a JSON Schema and the error codes | nothing |
| Tables | a generator that installs `md_revisions`, `md_suggestions` and `md_suggestion_hunks` | runs the migration; may add columns |
| The actor | the `Md::Agent::Principal` value object | builds it from its own users, API tokens or OAuth claims |
| Permissions | calls one `authorize` hook with `(principal, record, action)` and fails closed | implements the hook with Pundit, Action Policy or plain Ruby; decides draft versus published |
| Review UI | the `markdown_review` helper and Phlex component, hunk accept and reject endpoints (optional routes), a Stimulus controller | places it in its layout; may route accepts through its own operations |
| Provenance | columns on revisions, suggestions and hunks | displays them; decides any reader-facing disclosure |
| Audit | `ActiveSupport::Notifications` events for every read, proposal, decision and tool call | subscribes and persists them (Papyro: its audit table) |
| Rate limits | a default `rate_limit` on the gem's MCP and review controllers, configurable | tunes the budgets; limits its own endpoints |
| MCP | tool classes, a controller, a route helper, scope names; the `mcp` gem as an optional dependency | adds `gem "mcp"`; supplies authentication (a token lookup or an OAuth verifier) |
| LLM calls | a JSON Schema for the edit tool, a context builder, `Md::Suggestion.propose` | its own client, prompts, jobs and model choice (Papyro: the Gemini translation) |
| Markdown twins | a default `to_markdown`, the `markdown_alternate_link_tag` helper, the revision as a strong `ETag` and an `Md-Revision` header | the routes, which records are public, `/llms.txt` |

This refines the benchmark, which leaves `.md` twins and `/llms.txt` in the host (report, "Recommended direction"): the gem
ships only the generic pieces (`to_markdown`, the alternate-link helper, the revision header), and the host keeps the
routes, the publication rules and `/llms.txt`.

The hook is the benchmark's `authorize_suggestion` (design rule 4), renamed because it also guards reads and tool calls,
and given a principal instead of a user so that token-backed agents fit.

### Answer: reconciling concurrent human and agent edits

1. **Revisions are content-addressed.** A revision id is `sha256:` followed by the hex digest of the LF-normalised text.
   The gem stores a revision row for every distinct text that was saved through the gem or handed to an agent, so the
   text any agent read can always be found again. Because the id is a digest, the gem can check a write that requires the
   current revision by hashing the current text, even for a record saved outside the gem.
2. **Reads return the revision.** Every agent read returns the text together with its revision id. The reads are
   `md_get_document`, the markdown twin (in its `Md-Revision` header, with the same value as a strong `ETag`) and the
   Ruby context builder.
3. **Proposals may be stale; direct writes may not.** `propose` accepts any stored base revision and matches the edits
   against the base text, where the agent saw them. `apply`, the direct write, is off by default. It requires the base to
   be the current revision, like Google's `requiredRevisionId`, and otherwise answers `stale_revision` with the current id.
   The write itself is guarded by the record's optimistic lock (the benchmark's `lock_version` check), so a save between
   the revision check and the write fails instead of being lost.
4. **Hunks are rebased at review time.** Each hunk keeps its offsets in the base text. When the review UI loads, and again
   on accept, the gem diffs the base text against the current text and maps each hunk's range through that diff.
   - A hunk whose base range no human edit has touched maps cleanly and stays `pending`.
   - A hunk whose range overlaps a later edit becomes `conflict`. The reviewer sees both versions and cannot accept the
     hunk as it is, but can edit the replacement and accept that, or reject the hunk.
5. **Acceptance is one locked write.** Accepting hunks applies them to the current text in a transaction guarded by the
   record's optimistic lock. The write creates a new revision with combined provenance (agent author, human reviewer) and
   rebases the remaining pending hunks. If it hits a `StaleObjectError`, the review re-renders with the fresh text instead
   of failing silently.
6. **The editor learns about it.** An editor open on the record gets the new revision through the normal autosave
   conflict path (area EDIT). When the app uses Turbo Streams, it also gets a "suggestion accepted" broadcast (area RAILS).

### Answer: the patch contract

The Ruby API, the review endpoints and the MCP tools all use one request shape. Here is a proposal against
Papyro-like content:

```json
{
  "document": "doc_8Kq2",
  "locale": "es",
  "base_revision": "sha256:4f2a9c0e7d1b5a3c8e6f9d2b1a0c7e5f3d9b8a6c4e2f0d1b3a5c7e9f1d3b5a7c",
  "edits": [
    {
      "old_str": "El editor guarda markdown en la base de datos.",
      "new_str": "El editor guarda el markdown tal cual en la base de datos."
    },
    {
      "old_str": "## Conclusión\n",
      "new_str": "## Conclusiones\n",
      "replace_all": false
    }
  ],
  "rationale": "Aclara que el texto no se normaliza y corrige el título.",
  "dry_run": false
}
```

The `document` value is an opaque id that the gem issues for one markdown attribute of one record (the same id
`md_list_documents` returns and the `md://documents/{id}` resource uses). The gem resolves it only to records whose models declare
`has_markdown … suggestions: true`, then calls the `authorize` hook; it never accepts a GlobalID or a class name from an
agent.

Success (`propose`):

```json
{
  "suggestion_id": "sug_01JC9ZK7Q4",
  "state": "pending",
  "base_revision": "sha256:4f2a9c0e7d1b5a3c8e6f9d2b1a0c7e5f3d9b8a6c4e2f0d1b3a5c7e9f1d3b5a7c",
  "hunks": [
    { "id": "hunk_1", "edit_index": 0, "state": "pending", "line": 14 },
    { "id": "hunk_2", "edit_index": 1, "state": "pending", "line": 88 }
  ],
  "review_url": "https://example.com/md/suggestions/sug_01JC9ZK7Q4"
}
```

Failure (all or nothing, so nothing is stored):

```json
{
  "error": "invalid_edits",
  "message": "2 of 2 edits could not be matched against the base revision.",
  "edits": [
    { "index": 0, "code": "ambiguous_match", "matches": 3, "hint": "Add surrounding text to old_str or set replace_all." },
    { "index": 1, "code": "no_match", "hint": "Re-read the document; old_str must match the base revision byte for byte." }
  ],
  "current_revision": "sha256:9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d"
}
```

Error codes:

| Code | When | Per edit | Retry hint for the agent | MCP surface |
|---|---|---|---|---|
| `no_match` | `old_str` does not occur in the base text | yes | re-read; copy text exactly | `isError` result |
| `ambiguous_match` | `old_str` occurs more than once and `replace_all` is false | yes, with `matches` | widen `old_str` | `isError` result |
| `empty_old_str` | `old_str` is empty and the base text is not empty | yes | anchor the insert on neighbouring text | `isError` result |
| `overlapping_edits` | two edits touch the same base range | yes, both indexes | merge them into one edit | `isError` result |
| `noop_edit` | `old_str` equals `new_str` | yes | drop the edit | `isError` result |
| `forbidden_characters` | `new_str` contains bidi controls or Unicode tag characters | yes, with code points | remove them | `isError` result |
| `too_many_edits` | more edits than `max_edits` (default 100, Notion's limit) | no | split the proposal | `isError` result |
| `too_large` | the request or the resulting text exceeds the configured byte limit | no | shorten | `isError` result |
| `unknown_revision` | the base revision is not stored (never read through the gem, or pruned) | no | re-read | `isError` result |
| `stale_revision` | `apply` only: the base is not the current revision | no | re-read, or `propose` instead | `isError` result |
| `queue_full` | the actor already has the maximum number of pending suggestions on this document (with AGENT-21) | no | wait for review | `isError` result |
| `not_found` | no such document or locale for this actor | no | list documents | `isError` result |
| `insufficient_scope` | the token lacks the tool's scope | no | ask a human for a token with that scope | HTTP 403 with `WWW-Authenticate` |
| `forbidden` | the `authorize` hook refused this action on a document the actor may read | no | ask a human | `isError` result |
| `rate_limited` | the actor is over budget; the error carries `retry_after` | no | wait | HTTP 429 |

An empty base text is the one exception to `empty_old_str`: there, exactly one edit with an empty `old_str` is accepted
and becomes the whole new text (for example a first translation into an empty locale).

The last column shows how each code reaches an MCP client. The `authorize` hook runs inside the tool, so its refusal is a
tool result: `forbidden` when the actor may read the document but not perform the action, and `not_found` when it may
not read it, so the response does not reveal that the document exists. Codes the model can act on, including
`invalid_edits` (the envelope that carries the per-edit codes), are `isError` results. `insufficient_scope` and
`rate_limited` come from the HTTP layer as 403 and 429, and an authentication failure is HTTP 401, as the MCP
authorization specification requires.

### Answer: MCP tools and scopes

| Tool | Scope | Annotations | Does |
|---|---|---|---|
| `md_list_documents` | `md.read` | read-only, idempotent, closed world | pages through the documents the hook lets this actor read: id, record type label, attribute, title, locales, current revision, pending suggestion count |
| `md_get_document` | `md.read` | read-only, idempotent, closed world | returns markdown, revision, dialect version and headings (slug, level, text, line); an optional `heading` returns one section |
| `md_list_suggestions` | `md.read` | read-only, idempotent, closed world | lists the actor's own suggestions with hunk states and reviewer notes, so an agent learns what was accepted |
| `md_propose_edits` | `md.suggest` | not read-only, not destructive, not idempotent, closed world | the patch contract above; creates a pending suggestion |
| `md_withdraw_suggestion` | `md.suggest` | not read-only, not destructive, idempotent, closed world | withdraws one of the actor's own pending suggestions |
| `md_apply_edits` | `md.write` | not read-only, destructive, not idempotent, closed world | writes directly against the current revision; registered only when the app enables it, and still subject to the hook (Papyro: drafts only) |

A resource template, `md://documents/{id}{?locale}`, serves the same markdown as `md_get_document` for clients that
prefer resources. No tool accepts or rejects a suggestion, on purpose: review is a human act, as in Word's Agent Mode.
No tool fetches a URL or sends a message.

### Answer: plugging in the app's own LLM

The gem stays vendor-free. It offers three plain-Ruby pieces and no client:

```ruby
# 1. Context the app sends to its model: the exact stored text (LF), the revision and headings, plus a separate list of invisible characters.
context = Md::Agent.context_for(article, :body, locale: :es)
context.markdown   # => String (LF)
context.revision   # => "sha256:…"
context.invisibles # => [{ offset: 120, codepoint: "U+200B" }] (the markdown itself is never altered, so old_str copied from it matches)

# 2. A tool definition any SDK accepts (ruby_llm, anthropic, openai, gemini): name, description, JSON Schema.
Md::Patch.tool_definition # => { name: "md_propose_edits", description: "…", input_schema: { … } }

# 3. The model's tool input becomes a suggestion through the same path as MCP.
Md::Suggestion.propose(article, :body,
  locale: :es,
  base_revision: context.revision,
  edits: tool_input["edits"],
  rationale: tool_input["rationale"],
  author: Md::Agent::Principal.new(record: gemini_bot, kind: :agent, name: "Gemini translator", model: "gemini-2.5-flash"))
```

The app runs this in its own job with its own client. Papyro's Gemini translation becomes one caller of
`Md::Suggestion.propose`, so its output lands in the same review queue as an external agent's (benchmark, "Agents get
exact-string patches…"). The context lists invisible characters separately, and only the review UI shows them as
badges. For whole-text generation the app proposes one edit per paragraph or section, so the review keeps hunk
granularity; a first translation into an empty locale is the single empty-`old_str` edit that the contract allows for an
empty base.

## Requirements

The requirements are grouped by concern. Every MUST is needed for the agent layer's first release, which is the release
that ships the review UI (the benchmark roadmap puts read and propose first in 0.1, and the review UI and MCP in later
0.x releases). SHOULD items can follow in later 0.x releases.

### Contract and data model

- **AGENT-01** (MUST) The agent layer is opt-in: it loads only after `bin/rails generate md:suggestions MODEL` and a model
  declares it (`has_markdown :body, suggestions: true`), and the render core, viewer and editor never require its tables.
  A model that declares `suggestions: true` needs a `lock_version` column: `bin/rails generate md:suggestions MODEL` adds it
  to that model's table when it is missing, and otherwise boot raises an error that names the column. Acceptance: an app
  without the generator boots, renders and edits markdown and has no `md_*` tables, and declaring `suggestions: true` on
  a model without `lock_version` raises at boot with the column name.
- **AGENT-02** (MUST) The generator installs three tables (`md_revisions`, `md_suggestions`, `md_suggestion_hunks`) with
  indexes and foreign keys, scoped to record, attribute and an optional locale, in one reversible migration.
  Acceptance: the migration runs and rolls back on SQLite, PostgreSQL and MySQL in the gem's CI.
- **AGENT-03** (MUST) Revision ids are `sha256:` plus the hex digest of the LF-normalised text, and the gem stores a
  revision row for every distinct text saved through it or handed to an agent. Acceptance: two saves of identical text
  produce one row, and a CRLF copy and an LF copy of the same text produce the same id.
- **AGENT-04** (MUST) `Md::Patch` validates a request against the contract in this doc and is all or nothing. It checks
  exact matches against the base text, `replace_all`, empty `old_str`, empty-document inserts, overlaps, no-op edits, and
  edit and size limits. When any edit fails, nothing is stored and every failing edit is reported by index and code.
  Acceptance: a test table covers each error code except `queue_full` (tested with AGENT-21) with a fixture and asserts that no rows were written on failure, and a
  request naming a document id that resolves to no `suggestions: true` model gets `not_found`.
- **AGENT-05** (MUST) The contract is published as a JSON Schema (`Md::Patch.json_schema`) and a tool definition
  (`Md::Patch.tool_definition`) generated from one source, and the README shows the request, success and error examples
  of this doc. Acceptance: a test asserts that the MCP tool's input schema equals the Ruby tool definition's schema.
- **AGENT-06** (MUST) A suggestion stores one hunk per edit, with base offsets, `old_str`, `new_str` and a state
  (`pending`, `accepted`, `rejected`, `conflict`, `withdrawn`). The suggestion's own state is derived from its hunks.
  Base offsets are Ruby character offsets in the LF text, and the JavaScript review mode addresses hunks by id, never by
  offset (CodeMirror positions are UTF-16 code units). Acceptance: accepting one of two hunks leaves the suggestion `pending` with one accepted hunk.
- **AGENT-07** (MUST) Provenance is recorded on suggestions and on the revisions they produce:
  author (polymorphic, nullable), `author_kind` (`human`, `agent`, `system`; the benchmark's `author_type`, renamed
  because the polymorphic `author` association already uses the `author_type` column), agent display name, client or token id,
  origin (`ruby`, `mcp`, `review`), model and rationale. Each hunk also records its reviewer and decision time. Fields
  that an external client reports about itself, such as the model, are stored as self-reported. Acceptance: a revision
  produced by an accepted hunk exposes both the agent author and the human reviewer.
- **AGENT-08** (MUST) For records that declare `suggestions: true`, stored text and agent-facing text are LF-normalised
  before revisions are computed and edits are matched; the textarea behaviour behind it is confirmed by the EDIT area.
  Acceptance: an `old_str` copied from `md_get_document` matches a record saved from a browser textarea.
- **AGENT-09** (SHOULD) Revision retention is configurable (keep the last N per document, plus any revision that a pending
  suggestion references), with a pruning job. Acceptance: pruning never deletes the base of a pending suggestion.

### Concurrency

- **AGENT-10** (MUST) `propose` accepts any stored base revision and matches edits against that base text, so a slow
  agent's proposal survives human edits made since it read. Acceptance: a proposal against revision 1 succeeds after a
  human saved revision 2 with a change elsewhere in the document.
- **AGENT-11** (MUST) Pending hunks are rebased onto the current text when the review loads and when a hunk is accepted:
  each hunk's base range is mapped through the base-to-current diff, and a hunk whose range overlaps a later edit becomes
  `conflict` and cannot be accepted unchanged. Acceptance: a test edits the line a hunk targets, and the review shows that
  hunk as a conflict while the other hunk stays acceptable.
- **AGENT-12** (MUST) Accepting hunks is one transaction, guarded by the record's optimistic lock, that writes the text,
  a new revision and the hunk decisions, then rebases the remaining hunks. Acceptance: two simultaneous accepts on the same
  record produce one success and one refreshed review, never a lost update.
- **AGENT-13** (MUST) Direct writes (`apply`) are disabled by default. When enabled, they require the base revision to be
  the current one, otherwise answer `stale_revision` with the current id, and write in one transaction guarded by the
  record's optimistic lock as in AGENT-12, so a save between the check and the write fails instead of being lost.
  Acceptance: with the default configuration `md_apply_edits` is not listed and `Md::Patch.apply` raises a configuration
  error.
- **AGENT-14** (SHOULD) A reviewer can edit a hunk's replacement before accepting it, and the resulting revision records
  the hunk as human-modified. Acceptance: the produced revision's provenance marks the hunk as edited by the reviewer.
- **AGENT-36** (MUST) With direct writes enabled, a human save that lands between the revision check and the write makes
  `apply` answer `stale_revision` and write nothing. This requirement was added during review, after AGENT-35.
  Acceptance: a test that saves the record between the revision check and the write (through a stubbed seam) gets
  `stale_revision` and the human text survives.

### Review UI and neutralisation

- **AGENT-15** (MUST) The gem ships a review view: `markdown_review record, :body` for ERB, plus a Phlex component. It
  lists pending suggestions as hunks with a word-level diff, the agent's name and rationale, and the conflict state. It
  offers accept and reject for each hunk, and for all hunks of one suggestion. It works without JavaScript through plain
  forms. Acceptance: a system test with JavaScript disabled accepts one hunk and rejects another.
- **AGENT-16** (MUST) While a suggestion is pending, images it adds or changes render as placeholders that show the URL as
  text, and links it adds or changes render without `href`, showing the full destination with the host highlighted. The
  server makes no outbound request for them (no probe, embed or unfurl). Acceptance: in a browser test, rendering the
  review of a suggestion that adds an image and a link makes no request to either URL's host, and the HTML has no `src`
  or `href` for them.
- **AGENT-17** (MUST) The review handles links on the parsed AST (inline links, reference-style definitions and autolinks)
  and shows a destination change even when the link text is unchanged. Acceptance: a suggestion that only edits a
  reference definition's URL shows the old and the new destination in its hunk.
- **AGENT-18** (MUST) Invisible and deceptive characters in pending text are visible in the review:
  - zero-width characters and HTML comments appear as badges or as source text;
  - non-ASCII hosts appear in punycode;
  - agent edits that contain bidi controls or Unicode tag characters are refused with `forbidden_characters`.
  Acceptance: fixtures with U+200B, U+202E, U+E0041 and an IDN host produce a badge, a refusal, a refusal and a punycode host.
- **AGENT-19** (MUST) Rationale and other agent-supplied free text render as escaped plain text, never as markdown.
  Acceptance: a rationale that contains a markdown image renders as literal text.
- **AGENT-20** (MUST) The review view meets WCAG 2.2 AA: hunks can be reached and decided by keyboard, each control names
  the hunk it acts on, and state changes are announced. Acceptance: an axe check passes, and a keyboard-only system test
  accepts a hunk.
- **AGENT-21** (SHOULD) A hunk that deletes more than a configured share of the document (default 30%) carries a warning.
  Each actor has a cap on pending suggestions per document (default 5), and a proposal over the cap gets `queue_full`.
  Acceptance: a test proposal over each threshold shows the warning and gets the error.
- **AGENT-22** (SHOULD) The editor shows pending suggestions in a review mode built on `@codemirror/merge`. Each hunk (not
  each diff chunk) gets one accept and one reject control, which call the same endpoints as the review view. Acceptance:
  in a system test, two adjacent hunks render two pairs of controls.
- **AGENT-23** (COULD) New suggestions and decisions are broadcast to the open editors and review pages of the record
  through the broadcast mechanism the RAILS area defines. Acceptance: a second browser session sees a new suggestion without reloading.

### Authorization, rate limiting and audit

- **AGENT-24** (MUST) Every agent-layer entry point calls one hook that the app supplies,
  `config.authorize { |principal, record, action| }`, with the actions `read`, `propose`, `withdraw`, `apply` and
  `review`. When no hook is configured, the layer fails closed with an error that names the setting. Acceptance: with no
  hook, every tool and endpoint refuses, and the development error message shows the configuration snippet.
- **AGENT-25** (MUST) The actor is an `Md::Agent::Principal` (record, kind, display name, client id, scopes, model) that the
  app builds, and the gem never stores credentials. Acceptance: the README's Pundit example authorises a principal backed by
  an app model that has no gem-specific columns.
- **AGENT-26** (MUST) The gem's MCP and review controllers apply Rails `rate_limit` keyed on the principal, with separate,
  configurable read and write budgets (defaults: 60 reads and 20 writes per minute). Over budget, the gem's own `with:`
  handler answers HTTP 429 with a `Retry-After` header and the body `{"error":"rate_limited","retry_after":N}`; the budget
  is keyed after authentication resolves the principal, and the review controllers use a separate budget
  (own `name:`, default 120 decisions per minute) so a human accepting hunks one by one is not throttled. Acceptance: under the default budget, the 61st
  read request in a minute gets a 429 with `Retry-After`.
- **AGENT-27** (MUST) Every read, proposal, withdrawal, decision and tool call emits an `ActiveSupport::Notifications`
  event (`read.md`, `propose.md`, `withdraw.md`, `decide.md`, `tool_call.md`). The event carries the principal, record,
  action, revision, outcome and a digest of the arguments, so the app can persist an audit log. Acceptance: a test
  subscriber receives one event per call, with those keys.

### MCP

- **AGENT-28** (SHOULD) With `gem "mcp"` in the bundle, the gem offers the six tools and the resource template of this
  doc as `MCP::Tool` classes with the listed scopes and annotations. A controller serves them with a stateless server built
  per request, and one route helper mounts it (`md_mcp at: "/mcp"`). Acceptance: an MCP client lists the tools, and
  editing a tool class in development takes effect without restarting the server.
- **AGENT-29** (SHOULD) Each tool checks its scope inside the tool (`require_scopes!`; the RAILS spike confirms that it surfaces as HTTP 403, and if it does not, the controller checks
  the tool's scope before dispatch) and then calls the `authorize`
  hook. The endpoint answers 401 and 403 with `WWW-Authenticate` challenges as the MCP authorization specification
  describes, whether the app authenticates with an `authenticate` block (personal tokens) or an `mcp` gem verifier (OAuth).
  Acceptance: a token with only `md.read` gets a 403 `insufficient_scope` that names `md.suggest` when it proposes.
- **AGENT-30** (SHOULD) The MCP tools fetch no URL and send no data outside the app. Tool errors that the model can fix
  come back as `isError` results with the contract's codes. Acceptance: a test that proposes an ambiguous edit gets an
  `isError` result listing `ambiguous_match` and the number of matches.
- **AGENT-31** (COULD) A stdio entry point (`bin/rails md:mcp`) serves the same tools to local agents, with a principal
  taken from the environment. Acceptance: a local MCP client connected over stdio lists the read tools.

### Markdown twins and app-side LLM calls

- **AGENT-32** (SHOULD) A model with `has_markdown` gets a default `to_markdown` for Rails 8.1 `render markdown:` and a
  `markdown_alternate_link_tag` helper that emits `<link rel="alternate" type="text/markdown">`. Twin responses carry the
  revision in an `Md-Revision` header, set the same value explicitly as a strong quoted `ETag` (`"sha256:…"`; Rails
  `fresh_when(etag:)` would digest the value into a weak ETag), and send `Vary: Accept`. Acceptance: a request for a
  record's `.md` twin returns `text/markdown` with an `Md-Revision` header equal to the revision from `md_get_document`,
  and the HTML page links to the twin.
- **AGENT-33** (MUST) Twins and `md_get_document` serve accepted text only. Pending suggestions appear in no read path
  except the review. Acceptance: with a pending suggestion, the twin and the tool return the same text as before the
  proposal.
- **AGENT-34** (MUST) `Md::Agent.context_for` and `Md::Suggestion.propose` let an app feed any LLM and store its output as
  a suggestion, without the gem depending on an LLM gem or an HTTP client gem. Acceptance: the gemspec has no LLM
  dependency, and the README example proposes a suggestion from a stubbed model response.
- **AGENT-35** (COULD) An app action registered through the editor's toolbar extension point (owned by area EDIT) can run
  the app's LLM and call `Md::Suggestion.propose`, and the result appears in the editor's review mode without a reload.
  Acceptance: in the dummy app, such an action creates a pending suggestion that is visible in the editor's review mode.

## Developer experience notes

This layer is the most expensive part of the gem to adopt. Its cost is concentrated in one generator and one hook, and
the other three layers work without any of it.

| Requirements | What a newcomer adds | Cost and mitigation |
|---|---|---|
| AGENT-01, AGENT-02 | `bin/rails generate md:suggestions MODEL`, `bin/rails db:migrate`, `suggestions: true` on the model | Three tables, one option, and a `lock_version` column on the model's table if it lacks one (the generator adds it); the generator prints the next two steps |
| AGENT-24, AGENT-25 | one `authorize` block and a way to build a principal | The one mandatory decision. Because the layer fails closed, a forgotten hook shows a clear error and never leaves the door open. The README carries Pundit, Action Policy and plain-Ruby versions. |
| AGENT-15 to AGENT-20 | `<%= markdown_review @post, :body %>` on an edit page | One helper; the routes come from the engine unless the app turns them off to use its own operations |
| AGENT-04, AGENT-05, AGENT-34 | for in-app AI: `context_for`, `tool_definition`, `propose` | Three methods; the JSON Schema saves writing a tool definition by hand for each LLM SDK |
| AGENT-26, AGENT-27 | nothing by default; optionally budgets and a notifications subscriber | The defaults are safe; persisting an audit log is the app's choice, and the README shows how |
| AGENT-28 to AGENT-31 | `gem "mcp"`, `md_mcp at: "/mcp"`, an `authenticate` block | Optional; the controller pattern keeps code reloading working, which mounting at boot would break |
| AGENT-32, AGENT-33 | `format.md { render markdown: @post }` and the link helper | Uses Rails 8.1's own API; the gem only adds defaults |
| AGENT-13 | `config.allow_direct_apply = true` to enable `apply` | Off by default, so a newcomer cannot give agents unreviewed writes by accident |

A newcomer reaches a first reviewed agent edit in five steps, with no external service:

1. Run the generator for the model (it adds `lock_version` if missing).
2. Declare `suggestions: true` on the model.
3. Write the `authorize` block.
4. Add `markdown_review` to the edit page.
5. Call `Md::Suggestion.propose` from a console.

Error messages name the missing step, for example: "Md agent layer has no authorize hook: add `config.authorize` in
`config/initializers/md.rb`".

## Open decisions

- Should revisions be content-addressed snapshots (one row per distinct text that was saved or read by an agent) or a
  full history with one row per save? Recommendation: content-addressed snapshots. They keep the table small, make the
  `Md-Revision` header and `base_revision` the same value, and still let a host build full history on top.
- Should a patch request be all or nothing, or apply partially with warnings like Notion? Recommendation: all or
  nothing. A reviewer should never see a suggestion the agent did not fully intend, and the per-edit error list makes a
  retry cheap.
- Should `apply` (direct writes by agents) ship in 0.x at all? Recommendation: ship it disabled by default, behind the
  `md.write` scope and the hook. Papyro's drafts use it, and leaving it out invites apps to write their own unguarded path.
- How should MCP clients authenticate by default: an app-supplied bearer lookup (personal tokens), or OAuth verifiers
  only? Recommendation: an `authenticate` block as the default, with OAuth verifiers documented. Most Rails apps have no
  authorization server, and personal tokens get a first agent connected in minutes.
- Should the engine mount the review endpoints by default, or offer them only as a Ruby API? Recommendation: mount them
  by default, with a switch to turn them off. A review that works out of the box is the DX goal; Papyro turns the routes
  off and wraps the Ruby API in its own operations.
- Should the gem persist an audit table, or only emit events? Recommendation: events plus the provenance columns,
  because audit retention and storage are compliance choices that each app makes differently.
- Should the MCP module live in the gem (loaded when the `mcp` gem is present) or in a companion gem?
  Recommendation: in the gem, as an optional require. One version number and one README are easier for newcomers, and
  the soft dependency keeps it out of the core install.
- Should the layer refuse bidi controls and Unicode tag characters in agent edits, or only reveal them?
  Recommendation: refuse them, because no legitimate prose edit needs them. Reveal zero-width characters and HTML comments
  instead, because those occur in real text.
- What is the unit of review: the agent's edit or the diff chunk? Recommendation: the agent's edit, one hunk per edit,
  with the diff used only for display. The edit is what the agent intended and what the rebase tracks.
- Should the generator add `lock_version` to the host model's table, or should the gem lock with `record.lock!` and re-hash
  the text inside the transaction so it never touches host tables? Recommendation: add `lock_version`; it is the Rails
  idiom, the editor's autosave conflict detection uses the same column, and the generator states the change before
  writing it.
- Should a conflicting hunk fall back to applying where its `old_str` still occurs exactly once in the current text?
  Recommendation: no for the first release; a conflict shown to the reviewer is safer than a silent relocation, and the
  fallback can be added later without changing the contract.
- Should the gem ship markdown-twin helpers (`to_markdown`, `markdown_alternate_link_tag`, the revision header) or leave
  twins entirely to the host, where the benchmark placed them? Recommendation: ship the helpers; they are generic, they
  are the only agent read path without MCP, and the host still decides which records are public.

## Sources

The benchmark already settles some inputs:

- `docs/features/markdown-editor/reports/Markdown editor benchmark.md`, sections "Agents get exact-string patches that
  land as pending suggestions" and "What the gem provides";
- `docs/features/markdown-editor/research_notes/Markdown editor benchmark/agents_and_ai.md`, sections 1 to 6.

- https://developers.notion.com/reference/update-page-markdown (accessed 2026-11-03)
- https://developers.google.com/docs/api/how-tos/best-practices (accessed 2026-11-03)
- https://support.microsoft.com/office/agent-mode-in-word-647d5d14-eaec-4e8a-a574-7cefffa7f8f0 (accessed 2026-11-03)
- https://forum.cursor.com/t/bring-back-per-change-apply-inline-diff-review-you-re-throwing-away-your-best-ux-advantage/160856 (accessed 2026-11-03)
- https://www.sanity.io/docs/agent-actions/agent-action-cheatsheet (accessed 2026-11-03)
- https://codemirror.net/docs/ref/#merge (accessed 2026-11-03)
- https://www.npmjs.com/package/@codemirror/merge (accessed 2026-11-03)
- https://www.promptarmor.com/resources/notion-ai-unpatched-data-exfiltration (accessed 2026-11-03)
- https://www.promptarmor.com/resources/a-one-pixel-image-can-leak-your-data-in-huggingchat (accessed 2026-11-03)
- https://simonwillison.net/2025/Sep/19/notion-lethal-trifecta (accessed 2026-11-03)
- https://embracethered.com/blog/posts/2023/anthropic-fixes-claude-data-exfiltration-via-images (accessed 2026-11-03)
- https://embracethered.com/blog/posts/2023/data-exfiltration-in-azure-openai-playground-fixed (accessed 2026-11-03)
- https://embracethered.com/blog/posts/2025/cline-vulnerable-to-data-exfiltration (accessed 2026-11-03)
- https://embracethered.com/blog/posts/2023/google-gcp-generative-ai-studio-data-exfiltration-fixed (accessed 2026-11-03)
- https://embracethered.com/blog/posts/2023/advanced-plugin-data-exfiltration-trickery (accessed 2026-11-03)
- https://genai.owasp.org/llmrisk/llm01-prompt-injection/ (accessed 2026-11-03)
- https://nvd.nist.gov/vuln/detail/CVE-2021-42574 (accessed 2026-11-03)
- https://modelcontextprotocol.io/specification/2025-11-25/server/tools (accessed 2026-11-03)
- https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization (accessed 2026-11-03)
- https://blog.modelcontextprotocol.io/posts/ruby-sdk-1-0/ (accessed 2026-11-03)
- https://ruby.sdk.modelcontextprotocol.io/server/tools/ (accessed 2026-11-03)
- https://ruby.sdk.modelcontextprotocol.io/server/transports/ (accessed 2026-11-03)
- https://ruby.sdk.modelcontextprotocol.io/server/authorization/ (accessed 2026-11-03)
- https://guides.rubyonrails.org/8_1_release_notes.html (accessed 2026-11-03)
- https://blog.saeloun.com/2026/05/22/rails-8-1-markdown-rendering/ (accessed 2026-11-03)
- https://api.rubyonrails.org/classes/ActionController/RateLimiting/ClassMethods.html (accessed 2026-11-03)
- https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html (accessed 2026-11-03)
- https://llmstxt.org/ (accessed 2026-11-03)
