---
name: role-management
description: Guidance for implementing role-based access control (RBAC) in Rails using integer enums. Use when adding roles to users, defining role-based scopes, or implementing basic permission logic before layering in authorization gems like Pundit.
license: MIT
---

# Rails Role Management (Enum Pattern)

The professional standard for role management in Rails is the integer-based `enum`. This provides the performance of integers in the database with the readability of strings in the application code.

## Implementation Workflow

### 1. Database Schema
Always use an integer column with a default value and a NOT NULL constraint.
```ruby
# Migration
add_column :users, :role, :integer, default: 0, null: false
add_index :users, :role
```

### 2. Model Definition
Define roles in the model. Prefer the new hash syntax introduced in Rails 7+ for explicit mapping.
```ruby
class User < ApplicationRecord
  enum :role, { member: 0, admin: 1, editor: 2 }
end
```

### 3. Usage Patterns
* **Predicates**: `user.admin?`
* **Scopes**: `User.admin` (finds all admins)
* **Transitions**: `user.admin!` (updates role to admin)
* **Validation**: Rails automatically validates that the assigned value is included in the enum list.

## Core Standards
- **Explicit Mapping**: Always map names to integers (e.g., `{ admin: 1 }`) instead of using an array. This prevents role shifting if you reorder the list later.
- **Default Role**: The `0` value should always represent the least privileged role (e.g., `member` or `guest`).
- **Authorization Integration**: Use these role predicates inside **Pundit** policies for clean access control.

## Documentation
- **API Reference**: See [enum-api.md](references/enum-api.md) for a full list of generated methods.
- **Security**: See [security-best-practices.md](references/security-best-practices.md) regarding mass assignment and role escalation.
