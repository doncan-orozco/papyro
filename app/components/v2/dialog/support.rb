# frozen_string_literal: true

# What the dialog parts share: the render context pushed by Dialog and the as_child switch.
module Components::V2::Dialog::Support
  private

  def root_context
    context[Components::V2::Dialog::ROOT_KEY] or raise ArgumentError, "#{self.class.name} must be used within Dialog"
  end

  def state_of(root) = root[:open] ? "open" : "closed"

  def render_part(tag_name, as_child, attrs, &)
    return render_as_child(as_child, **attrs, &) if as_child

    tag(tag_name, **attrs, &)
  end
end
