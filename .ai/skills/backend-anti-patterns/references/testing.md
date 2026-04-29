# Backend Anti-Patterns: Testing

## Principle

Test observable behavior and public contracts, not incidental implementation details.

## Avoid

- asserting private method calls
- stubbing every internal collaborator of an operation
- tests that mirror the implementation line by line
- brittle expectations on internal operation keys that are not part of the public payload

```ruby
# BAD
Articles::Operation::Create.any_instance.expects(:validate_input)
```

## Prefer

- asserting persisted state changes
- asserting returned result shape and documented payload keys
- asserting redirect/render status and visible error handling in controller tests
- asserting side effects at the boundary where they matter

```ruby
result = Articles::Operation::Create.new.call(params: valid_params)

assert_predicate result, :success?
assert_instance_of Article, result.value![:model]
```

```ruby
result = Articles::Operation::Create.new.call(params: invalid_params)

assert_predicate result, :failure?
assert result.failure[:errors].key?(:title)
```

## Job Tests

Jobs should test queue behavior and failure policy, not re-prove the entire operation.

Prefer:
- faking the operation result object
- asserting raised exceptions only when the job intentionally converts failures into errors
- asserting IDs are passed through, not full AR objects
