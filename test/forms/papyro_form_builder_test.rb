require "test_helper"

class PapyroFormBuilderTest < ActiveSupport::TestCase
  test "field renders hint and validation errors" do
    user = User.new(email_address: "")
    user.errors.add(:email_address, "can't be blank")

    html = ApplicationController.render(
      inline: <<~ERB,
        <%= form_with model: user, url: "/users" do |form| %>
          <%= form.field :email_address,
            as: :email_field,
            label: "Email",
            hint: "Enter your email",
            before_input: "<span>Before input</span>".html_safe,
            options: { placeholder: "name@example.com" } %>
        <% end %>
      ERB
      locals: { user: user }
    )

    assert_includes html, "Enter your email"
    assert_includes html, "Before input"
    assert_includes html, "text-xs text-destructive"
    assert_includes html, "Email address can&#39;t be blank"
    assert_includes html, "aria-invalid=\"true\""
  end

  test "field renders select input" do
    user = User.new(email_address: "one@example.com")

    html = ApplicationController.render(
      inline: <<~ERB,
        <%= form_with model: user, url: "/users" do |form| %>
          <%= form.field :role,
            as: :select,
            label: "Role",
            choices: [["Admin", "admin"], ["Author", "author"]],
            html_options: { class: "role-select" } %>
        <% end %>
      ERB
      locals: { user: user }
    )

    assert_includes html, "<select"
    assert_includes html, "role-select"
    assert_includes html, ">Admin<"
    assert_includes html, ">Author<"
  end

  test "submit keeps base and custom classes" do
    user = User.new(email_address: "one@example.com")

    html = ApplicationController.render(
      inline: <<~ERB,
        <%= form_with model: user, url: "/users" do |form| %>
          <%= form.submit "Save", class: "my-submit" %>
        <% end %>
      ERB
      locals: { user: user }
    )

    assert_includes html, "my-submit"
    assert_includes html, "bg-primary"
  end

  test "field_input raises for unsupported type" do
    builder = PapyroFormBuilder.new(:user, User.new, ActionView::Base.empty, {})

    error = assert_raises(ArgumentError) do
      builder.send(:field_input, :email_address, as: :unsupported, choices: nil, options: {}, html_options: {})
    end

    assert_includes error.message, "Unsupported field type"
  end
end
