# frozen_string_literal: true

# What the accordion parts share: the render context pushed by Accordion and Accordion::Item.
module Components::V2::Accordion::Support
  private

  def root_context
    context[Components::V2::Accordion::ROOT_KEY] or raise ArgumentError, "#{self.class.name} must be used within Accordion"
  end

  def item_context
    context[Components::V2::Accordion::ITEM_KEY] or raise ArgumentError, "#{self.class.name} must be used within Accordion::Item"
  end

  def state_of(item) = item[:open] ? "open" : "closed"

  def disabled_data(item) = item[:disabled] ? "" : nil
end
