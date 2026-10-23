# frozen_string_literal: true

# Lucide icon for host and engine views.
#
# Renders `Chadcn::Icon` when the chadcn catalog knows the name, and the
# lucide-rails paths otherwise, with the same attributes and `lucide lucide-<name>`
# classes either way. Like `Chadcn::Icon` it adds no size class: the caller (or a
# chadcn parent such as a button) sizes it. Legacy spellings (`:alert_circle`,
# `:home`, underscores) are accepted. `size:` sets width and height; an explicit
# `width:` or `height:` wins over it. Caller attributes override the defaults on
# both paths (`class` is merged, `aria` is deep-merged).
#
# Usage:
#   render Components::Shared::Icon.new(:search, class: "size-4")
#   render Components::Shared::Icon.new(:camera, size: 24)
module Components
  module Shared
    class Icon < Components::Base
      LEGACY_NAMES = {
        "alert-circle" => "circle-alert",
        "alert-triangle" => "triangle-alert",
        "home" => "house"
      }.freeze

      # mirrors Chadcn::Icon#default_attrs so both paths emit the same attributes
      LUCIDE_DEFAULTS = {
        xmlns: "http://www.w3.org/2000/svg",
        width: 24,
        height: 24,
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: 2,
        stroke_linecap: "round",
        stroke_linejoin: "round",
        aria: { hidden: "true" }
      }.freeze
      private_constant :LUCIDE_DEFAULTS

      def initialize(name, size: nil, **attrs)
        @name = normalize(name)
        @attrs = size ? { width: size, height: size }.merge(attrs) : attrs
      end

      def view_template
        key = catalog_key
        return render_lucide unless key

        render Chadcn::Icon.new(key, **@attrs)
      end

      private

      def normalize(name)
        key = name.to_s.downcase.tr("_", "-")
        LEGACY_NAMES.fetch(key, key)
      end

      def catalog_key
        Chadcn::Icons::Catalog::ALIASES[@name] || (@name if Chadcn::Icons::Catalog::NODES.key?(@name))
      end

      # raises ArgumentError when lucide-rails does not know the name either
      def render_lucide
        paths = LucideRails::IconProvider.icon(@name)
        svg(**lucide_attrs) { raw(safe(paths)) }
      end

      def lucide_attrs
        merged = LUCIDE_DEFAULTS.merge(@attrs.except(:class, :aria))
        merged.merge(
          class: cn("lucide lucide-#{@name}", @attrs[:class]),
          aria: LUCIDE_DEFAULTS[:aria].merge(@attrs.fetch(:aria, {}))
        )
      end
    end
  end
end
