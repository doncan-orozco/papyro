# Rails Enum Generated Methods

When you define `enum :role, { member: 0, admin: 1 }`, Rails provides:

## 1. Scopes
- `User.member`: Returns all members.
- `User.not_member`: Returns everyone except members.

## 2. Predicates
- `user.member?`: Returns true/false.
- `user.admin?`: Returns true/false.

## 3. Bang Methods (Persisted Updates)
- `user.member!`: Updates the database record to `role: 0`.
- `user.admin!`: Updates the database record to `role: 1`.

## 4. Translation & Display
To show the role in a view:
`<%= user.role.humanize %>` # Output: "Member" or "Admin"
