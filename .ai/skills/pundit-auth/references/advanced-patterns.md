# Advanced Pundit Patterns

## 1. Permitted Attributes (Strong Params)
Centralize what a user can edit based on their role directly in the policy.

```ruby
# app/policies/article_policy.rb
def permitted_attributes
  if user.admin?
    [:title, :body, :slug, :featured]
  else
    [:title, :body]
  end
end

# app/controllers/articles_controller.rb
def update
  @article = Article.find(params[:id])
  authorize @article
  if @article.update(permitted_attributes(@article))
    # ...
  end
end
```

## 2. Headless Policies
For dashboards or search pages where there is no specific model instance.

```ruby
# app/policies/dashboard_policy.rb
class DashboardPolicy < Struct.new(:user, :dashboard)
  def show?
    user.present?
  end
end

# In Controller
authorize :dashboard, :show?
```

## 3. Multiple Contexts
If you need more than just `current_user` (e.g., user + IP address), pass a context object to Pundit.
```ruby
# app/controllers/application_controller.rb
def pundit_user
  UserContext.new(current_user, request.remote_ip)
end
```
