# Session Learnings: Mutation Flows

Compact decisions captured from the latest operation/contract refactor.

## Operation Shape

- `ApplicationOperation` inherits from `Dry::Operation`.
- In `call`, return a plain payload hash (for example `{ model: article }`), not `Success(...)`.
- Reason: `Dry::Operation` wraps `call` return values; explicit `Success(...)` in `call` causes double wrapping.

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

## Form Object Guidance

- Avoid form-object orchestration for simple CRUD updates.
- Prefer contract + model assignment + model validations unless a dedicated form object is truly required by complex UI composition.

## Failure Payloads

- Keep failure payloads consistent: `{ model:, errors: }`.
- Contract failures should inject errors into an ActiveModel instance before returning Failure.
