# frozen_string_literal: true

class Components::Base < Phlex::HTML
  SHADCN_VERSION = "2.3.0"

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end

  protected

  # Merge component's base classes with any custom classes passed in attrs
  # Ensures custom classes take precedence while preserving component styles
  #
  # Example:
  #   merged_classes  # => "flex items-center mt-4 mb-2"
  #   where:
  #   - classes = "flex items-center"
  #   - @attrs[:class] = "mt-4 mb-2"
  def merged_classes
    [ classes, @attrs&.dig(:class) ].compact.join(" ")
  end

  # Extract class attribute from @attrs to avoid passing it twice in view_template
  # Returns attrs without the :class key to prevent duplication
  #
  # Usage:
  #   div(class: merged_classes, **attrs_without_class)
  def attrs_without_class
    @attrs&.except(:class) || {}
  end

  private

  # Override in subclasses to define component's base classes
  # Example: "flex items-center justify-center rounded-lg"
  def classes
    ""
  end
end
