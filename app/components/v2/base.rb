# frozen_string_literal: true

# Parent of every V2 (shadcn port) part. Provides attribute merging, the Radix Slot merge used by `as_child:`
# and the generated yielded-root DX helpers. See .ai/skills/shadcn-port/references/api-mapping.md.
class Components::V2::Base < Components::Base
  ELEMENT_METHODS = (Phlex::HTML::StandardElements.public_instance_methods +
                     Phlex::HTML::VoidElements.public_instance_methods).freeze

  # React DOM props written as snake_case kwargs (`tab_index:`) => the real HTML attribute (`tabindex`).
  # Without this Phlex dasherizes them into invalid names (`tab-index`). aria-*/data-* are handled separately.
  DOM_ATTRIBUTES = (%w[
    tabIndex formNoValidate readOnly maxLength minLength autoComplete autoFocus autoCapitalize autoCorrect autoSave
    spellCheck contentEditable crossOrigin encType formAction formEncType formMethod formTarget noValidate colSpan
    rowSpan srcSet srcDoc useMap dateTime inputMode enterKeyHint accessKey allowFullScreen playsInline hrefLang
    srcLang cellPadding cellSpacing charSet contextMenu controlsList disablePictureInPicture disableRemotePlayback
    frameBorder marginHeight marginWidth radioGroup referrerPolicy popoverTarget popoverTargetAction fetchPriority
    itemID itemProp itemRef itemScope itemType
  ].flat_map { |name| [ name, name.underscore ].uniq.map { |spelling| [ spelling, name.downcase.to_sym ] } }
    .to_h
    .merge(%w[httpEquiv http_equiv].to_h { |spelling| [ spelling, :"http-equiv" ] })
    .merge(%w[acceptCharset accept_charset].to_h { |spelling| [ spelling, :"accept-charset" ] })
    .merge("className" => :class, "class_name" => :class, "htmlFor" => :for, "html_for" => :for)
    .freeze)

  # Ruby 3.2+: runs for every constant assigned in a class body, nested `class Header < Base` included.
  # Defines `root.header(**attrs, &block)` == `render Root::Header.new(**attrs), &block`.
  # An HTML element name (`header`, `title`) may be shadowed on purpose: roots use `tag(:header)` internally.
  def self.const_added(name)
    super
    part = begin
      const_get(name, false)
    rescue NameError
      nil
    end
    return unless part.is_a?(Class) && part < Components::V2::Base

    helper = name.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
    if reserved_helper_names.include?(helper)
      raise ArgumentError, "helper ##{helper} (from #{name}) would override a Ruby/Phlex API method"
    end

    # Resolved at call time (not captured): `const_added` fires when the class is created, before its file has defined `initialize`.
    define_method(helper) { |**attrs, &block| render self.class.const_get(name, false).new(**attrs), &block }
  end

  def self.reserved_helper_names
    (Object.public_instance_methods + Components::Base.public_instance_methods) - ELEMENT_METHODS
  end

  # Slot accessors used by `render_as_child` on the child instance (components keep caller props in @attrs).
  def as_child_attrs = @attrs || {}

  # `slot_class` is joined plainly in front of the child's own (cn-resolved) class, like Radix does.
  def receive_slot(attrs, slot_class)
    @attrs = attrs
    @slot_class = slot_class
  end

  protected

  # `"icon-sm"`, `:icon_sm` and `"icon_sm"` all become `"icon-sm"` (React variant keys).
  def normalize_option(value)
    value&.to_s&.tr("_", "-")
  end

  # Ids for aria wiring: `ids("dialog-1")[:title]` => "dialog-1-title". Without a base a random one is used.
  def ids(base = nil)
    base ||= "v2-#{SecureRandom.alphanumeric(6).downcase}"
    Hash.new { |_, part| "#{base}-#{part.to_s.tr("_", "-")}" }
  end

  # Component defaults + caller attrs: `data:`/`aria:` deep-merged (caller wins), `class` through `cn`
  # (caller wins on Tailwind conflicts), `data-action` descriptors concatenated (defaults first).
  def merge_attrs(defaults, attrs)
    defaults = canonical_attrs(defaults)
    attrs = canonical_attrs(attrs)
    merged = defaults.deep_merge(attrs)
    actions = [ defaults.dig(:data, :action), attrs.dig(:data, :action) ].compact_blank
    merged[:data] = (merged[:data] || {}).merge(action: actions.join(" ")) if actions.any?
    css = flatten_class_inputs([ @slot_class, cn(defaults[:class], attrs[:class]) ]).join(" ")
    css.empty? ? merged.except(:class) : merged.merge(class: css)
  end

  # Radix `Slot`: renders `child` (a V2 component instance, or a tag symbol) with `slot_attrs` merged in,
  # exactly like `@radix-ui/react-slot` mergeProps. NOT `merge_attrs`: no tailwind-merge here.
  def render_as_child(child, **slot_attrs, &block)
    slot = canonical_attrs(slot_attrs)
    if child.is_a?(Symbol) || child.is_a?(String)
      tag(child.to_sym, **slot, &block)
    else
      child.receive_slot(slot_merge(slot.except(:class), canonical_attrs(child.as_child_attrs)), slot[:class])
      render(child, &block)
    end
  end

  private

  # Canonical shape: top-level keys as given (React DOM prop names mapped to HTML ones), `data`/`aria` always nested
  # hashes with underscored symbol keys (flat `"data-foo"` / `:"aria-label"` keys are folded in). Like React, boolean
  # aria/data values render as "true"/"false" (Phlex would render a bare attribute / drop it).
  def canonical_attrs(attrs)
    result = {}
    (attrs || {}).each do |key, value|
      flat = key.to_s
      group = flat[/\A(data|aria)-/, 1]
      if group
        (result[group.to_sym] ||= {})[flat.delete_prefix("#{group}-").tr("-", "_").to_sym] = stringify_boolean(value)
      elsif %w[data aria].include?(flat)
        nested = (result[flat.to_sym] ||= {})
        value.each { |k, v| nested[k.to_s.tr("-", "_").to_sym] = stringify_boolean(v) }
      else
        result[DOM_ATTRIBUTES.fetch(flat, key)] = value
      end
    end
    result
  end

  def stringify_boolean(value)
    [ true, false ].include?(value) ? value.to_s : value
  end

  def slot_merge(slot, child)
    merged = slot.deep_merge(child) # child wins everything by default
    data = merged[:data] ||= {}
    actions = [ child.dig(:data, :action), slot.dig(:data, :action) ].compact_blank
    data[:action] = actions.join(" ") if actions.any?
    controllers = [ slot.dig(:data, :controller), child.dig(:data, :controller) ].compact_blank.flat_map { |c| c.to_s.split }.uniq
    data[:controller] = controllers.join(" ") if controllers.any?
    merged.delete(:data) if data.empty?

    merged[:style] = merge_styles(slot[:style], child[:style]) if slot[:style] && child[:style]

    if child.dig(:aria, :describedby)
      ids = [ child.dig(:aria, :describedby), slot.dig(:aria, :describedby) ].compact_blank.flat_map { |i| i.to_s.split }.uniq
      merged[:aria] = merged[:aria].merge(describedby: ids.empty? ? nil : ids.join(" "))
    end
    merged
  end

  def merge_styles(slot_style, child_style)
    return slot_style.merge(child_style) if slot_style.is_a?(Hash) && child_style.is_a?(Hash)

    [ style_string(slot_style), style_string(child_style) ].join("; ")
  end

  def style_string(style)
    style.is_a?(Hash) ? style.map { |k, v| "#{k.to_s.tr("_", "-")}: #{v}" }.join("; ") : style.to_s.strip.chomp(";")
  end
end
