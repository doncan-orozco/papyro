# frozen_string_literal: true

# Radix DialogPortal: renders no element. Its children ship in an inert template that the controller mounts directly in
# the container (a CSS selector, default body) while the dialog is open, or always with force_mount.
class Components::V2::Dialog::Portal < Components::V2::Base
  include Components::V2::Dialog::Support

  def initialize(force_mount: false, container: nil)
    @options = { forceMount: force_mount, container: }.compact
    super()
  end

  def view_template
    root = root_context
    previous = context[Components::V2::Dialog::PORTAL_KEY]
    context[Components::V2::Dialog::PORTAL_KEY] = true
    template(data: { v2__dialog_template: root[:content_id], v2__dialog_options: @options.to_json }) { yield if block_given? }
  ensure
    context[Components::V2::Dialog::PORTAL_KEY] = previous
  end
end
