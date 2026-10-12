# frozen_string_literal: true

# Radix DialogPortal: renders no element. Its children ship in an inert template that the controller mounts directly in
# the body while the sheet is open.
class Components::V2::Sheet::Portal < Components::V2::Base
  include Components::V2::Sheet::Support

  def view_template
    root = root_context
    previous = context[Components::V2::Sheet::PORTAL_KEY]
    context[Components::V2::Sheet::PORTAL_KEY] = true
    template(data: { v2__dialog_template: root[:content_id], v2__dialog_options: "{}" }) { yield if block_given? }
  ensure
    context[Components::V2::Sheet::PORTAL_KEY] = previous
  end
end
