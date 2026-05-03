# Session Learnings: Mutation Flows

Compact decisions captured from the latest operation/contract refactor.

## Operation Shape

- `ApplicationOperation` inherits from `Dry::Operation`.
- In `call`, return a plain payload hash (for example `{ model: article }`), not `Success(...)`.
- Reason: `Dry::Operation` wraps `call` return values; explicit `Success(...)` in `call` causes double wrapping.
- If an intermediate step only instantiates a model and passes it forward with no business rule checks, collapse it into the persistence step to keep the operation concise.

## Validation Boundaries

- Contracts are structural-only:
  - types/coercion/sanitization
  - key presence/optionality
- Models enforce state/database rules:
  - uniqueness
  - state transitions
  - max lengths and format constraints tied to persisted state

## Update Contract Rules

- Update contracts must accept partial payloads (optional keys).
- Do not add `prepare_defaults` to satisfy required contract keys.

## Update Operation Rules

- Use contract -> assign attributes -> persist pattern.
- Assign only keys present in validated params.
- Ownership fields (for example `user_id`) must not be mutable in update flows.
- Prefer `model.assign_attributes(validated_attributes)` when nested attributes are already supported by the model and contract.

## State Transition Operation Rules

- Use one operation per business intent (for example `Publish` and `Unpublish`) instead of action switches in a single operation.
- Avoid `action` flag branching (`if action == ...`) for domain commands.
- Controller actions should map 1-to-1 to operations (`create` -> `Publish`, `destroy` -> `Unpublish`).
- For a single `update`/`save` write, avoid explicit transaction wrappers unless coordinating multiple writes.

## Create Operation Rules

- For invalid contract re-render models, preserve user-typed fields using permitted params to avoid clearing valid form input.
- Do not repopulate password fields on failure; exclude `:password` and `:password_confirmation` when building the invalid model.
- When model supports nested assignment (for example `accepts_nested_attributes_for :profile`), avoid manual nested mapping in operations.

## Form Object Guidance

- Avoid form-object orchestration for simple CRUD updates.
- Prefer contract + model assignment + model validations unless a dedicated form object is truly required by complex UI composition.

## Failure Payloads

- Keep failure payloads consistent: `{ model:, errors: }`.
- Contract failures should inject errors into an ActiveModel instance before returning Failure.
