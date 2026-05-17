# Testing Pundit Policies

Pundit policies are easy to test because they are POROs. Avoid integration tests for complex logic; use unit tests for the policy class itself.

## RSpec Pattern
Use the `pundit` matcher for clean, readable tests.

```ruby
# spec/policies/article_policy_spec.rb
RSpec.describe ArticlePolicy do
  subject { described_class.new(user, article) }

  let(:article) { Article.create }

  context "being an admin" do
    let(:user) { User.create(role: :admin) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "being a guest" do
    let(:user) { nil }
    it { is_expected.to forbid_action(:update) }
  end
end
```
