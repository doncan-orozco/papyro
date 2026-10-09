# Security & Role Escalation

## 1. Strong Parameters
NEVER include `:role` in your standard `user_params` for public registration or profile updates. This prevents "Mass Assignment" attacks where a user can promote themselves to admin via a CURL request.

```ruby
# WRONG (Security Vulnerability)
def user_params
  params.require(:user).permit(:email, :password, :role)
end

# RIGHT
def user_params
  params.require(:user).permit(:email, :password) # Role is handled by internal logic or separate admin UI
end
```

## 2. Protected Transitions
Only allow roles to be changed by an existing admin. Use a Pundit policy to guard the update action:

```ruby
class UserPolicy < ApplicationPolicy
  def update_role?
    user.admin? && !record.admin? # Only admins can change roles, but can't demote themselves (optional logic)
  end
end
```
