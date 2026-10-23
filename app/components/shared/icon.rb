# frozen_string_literal: true

# Lucide icon for host and engine views.
#
# Renders `Chadcn::Icon` when the chadcn catalog knows the name, and the
# lucide-rails paths otherwise, with the same attributes and `lucide lucide-<name>`
# classes either way. Like `Chadcn::Icon` it adds no size class: the caller (or a
# chadcn parent such as a button) sizes it. Legacy spellings (`:alert_circle`,
# `:home`, underscores) are accepted.
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

      def initialize(name, size: nil, **attrs)
        @name = normalize(name)
        @attrs = size ? attrs.merge(width: size, height: size) : attrs
      end

      def view_template
        key = catalog_key
        if key
          render Chadcn::Icon.new(key, **@attrs)
        else
          render_lucide
        end
      end

      private

      def normalize(name)
        key = name.to_s.downcase.tr("_", "-")
        LEGACY_NAMES.fetch(key, key)
      end

      def catalog_key
        Chadcn::Icons::Catalog::ALIASES.fetch(@name) { @name if Chadcn::Icons::Catalog::NODES.key?(@name) }
      end

      # raises ArgumentError when lucide-rails does not know the name either
      def render_lucide
        paths = LucideRails::IconProvider.icon(@name)
        svg(**lucide_attrs, class: cn("lucide lucide-#{@name}", @attrs[:class]), **attrs_without_class) { raw(safe(paths)) }
      end

      def lucide_attrs
        LucideRails.default_options.symbolize_keys.except(*attrs_without_class.keys.map(&:to_sym))
          .merge(xmlns: "http://www.w3.org/2000/svg")
      end
    end
  end
end
