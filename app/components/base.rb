# frozen_string_literal: true

class Components::Base < Phlex::HTML
  SHADCN_VERSION = "2.3.0"

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end

  protected

  # Merge component's base classes with any custom classes passed in attrs
  # Uses tailwind-merge to intelligently resolve Tailwind class conflicts
  # Mimics React's cn(...inputs) pattern with clsx + twMerge behavior
  #
  # Example:
  #   merged_classes  # => "flex items-center rounded-full"
  #   where:
  #   - classes = "flex items-center rounded-md"
  #   - @attrs[:class] = "rounded-full"
  #   (rounded-full wins, rounded-md is dropped)
  def merged_classes
    cn(classes, @attrs&.dig(:class))
  end

  # Merge multiple class inputs intelligently, resolving Tailwind conflicts
  # Supports strings, arrays, hashes (truthy keys), nested arrays, and nil
  # Mirrors React's cn(...inputs: ClassValue[]) => twMerge(clsx(inputs))
  #
  # Examples:
  #   cn("flex items-center", "mt-4")  # => "flex items-center mt-4"
  #   cn("rounded-md", "rounded-full")  # => "rounded-full" (conflict resolved)
  #   cn("flex", ["items-center", { "mt-4" => true, "mb-2" => false }])
  #   # => "flex items-center mt-4"
  def cn(*inputs)
    flattened = flatten_class_inputs(inputs)
    return "" if flattened.empty?

    self.class.tw_merger.merge(flattened.join(" "))
  end

  # Extract class attribute from @attrs to avoid passing it twice in view_template
  # Returns attrs without the :class key to prevent duplication
  #
  # Usage:
  #   div(class: merged_classes, **attrs_without_class)
  def attrs_without_class
    @attrs&.except(:class) || {}
  end


  def disable_layout_flash_messages
    content_for :flash do
      div
    end
  end

  private

  # Override in subclasses to define component's base classes
  # Example: "flex items-center justify-center rounded-lg"
  def classes
    ""
  end

  # Recursively flatten class inputs (clsx semantics)
  # Handles: String, Array, Hash (truthy keys only), nil
  def flatten_class_inputs(inputs)
    result = []

    inputs.each do |input|
      case input
      when String
        result << input unless input.empty?
      when Array
        result.concat(flatten_class_inputs(input))
      when Hash
        input.each do |key, value|
          result << key.to_s if value
        end
      when nil
        # Skip nil values
      else
        result << input.to_s
      end
    end

    result
  end

  # Memoized TailwindMerge::Merger instance (class-level)
  # Shared across all component instances for performance
  def self.tw_merger
    @tw_merger ||= TailwindMerge::Merger.new
  end
end
