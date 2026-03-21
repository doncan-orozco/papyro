# frozen_string_literal: true

class PapyroFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_CLASS = "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
  TEXTAREA_CLASS = "flex min-h-[60px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
  SELECT_CLASS = "flex h-9 w-full items-center justify-between rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
  SUBMIT_CLASS = "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 h-9 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
  HINT_CLASS = "text-xs text-muted-foreground"

  def text_field(method, options = {})
    super(method, merge_input_options(method, options))
  end

  def email_field(method, options = {})
    super(method, merge_input_options(method, options))
  end

  def password_field(method, options = {})
    super(method, merge_input_options(method, options))
  end

  def search_field(method, options = {})
    super(method, merge_input_options(method, options))
  end

  def url_field(method, options = {})
    super(method, merge_input_options(method, options))
  end

  def text_area(method, options = {})
    super(method, merge_field_options(method, options, TEXTAREA_CLASS))
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    super(method, choices, options, merge_field_options(method, html_options, SELECT_CLASS), &block)
  end

  def submit(value = nil, options = {})
    super(value, merge_class(options, SUBMIT_CLASS))
  end

  def field(method, as:, label:, hint: nil, choices: nil, options: {}, html_options: {}, before_input: nil)
    @template.content_tag(:div, class: "space-y-2") do
      parts = []
      parts << component_label(method, label)
      parts << before_input if before_input.present?
      parts << field_input(method, as: as, choices: choices, options: options, html_options: html_options)
      parts << @template.content_tag(:p, hint, class: HINT_CLASS) if hint.present?
      parts << field_errors(method)
      @template.safe_join(parts.compact)
    end
  end

  def field_errors(method)
    return if error_messages_for(method).empty?

    @template.safe_join(
      error_messages_for(method).map { |message|
        @template.content_tag(:p, message, class: "text-xs text-destructive")
      }
    )
  end

  private

  def field_input(method, as:, choices:, options:, html_options:)
    case as
    when :text_field, :email_field, :password_field, :search_field, :url_field, :text_area
      public_send(as, method, options)
    when :markdown_area
      merged = merge_field_options(method, options, TEXTAREA_CLASS)
      public_send(as, method, **merged)
    when :select
      select(method, choices || [], options, html_options)
    else
      raise ArgumentError, "Unsupported field type: #{as}"
    end
  end

  def component_label(method, text)
    @template.render Components::Ui::Label.new(for: field_id(method)) { text }
  end

  def merge_input_options(method, options)
    merge_field_options(method, options, INPUT_CLASS)
  end

  def merge_field_options(method, options, base_class)
    merged = merge_class(options, base_class)
    return merged unless has_errors?(method)

    merged[:aria] = (merged[:aria] || {}).merge(invalid: true)
    merged
  end

  def merge_class(options, base_class)
    options = options.dup
    options[:class] = [ base_class, options[:class] ].compact.join(" ")
    options
  end

  def error_messages_for(method)
    return [] unless object&.respond_to?(:errors)

    errors = object.errors

    if errors.respond_to?(:full_messages_for)
      errors.full_messages_for(method)
    elsif errors.respond_to?(:messages) && errors.messages[method].present?
      errors.messages[method].map do |message|
        if errors.respond_to?(:full_message)
          errors.full_message(method, message)
        else
          "#{method.to_s.humanize} #{message}"
        end
      end
    elsif errors.respond_to?(:where)
      errors.where(method).map do |error|
        error.respond_to?(:full_message) ? error.full_message : error.message.to_s
      end
    else
      Array(errors[method]).map(&:to_s)
    end
  end

  def has_errors?(method)
    error_messages_for(method).any?
  end
end
