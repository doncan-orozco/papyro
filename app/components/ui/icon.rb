module Components
  module Ui
    # Wrapper around server-rendered SVG icons.  By default the component will
    # use the `lucide-rails` gem, but the `source:` keyword allows us to add
    # other icon providers in the future (heroicons, custom SVG sprite, etc.).
    #
    # Usage examples:
    #
    #   Components::Ui::Icon.new(:home)
    #   Components::Ui::Icon.new(:search, size: 20, class: "text-muted")
    #   Components::Ui::Icon.new(:settings, source: :lucide, size: 24)
    #
    # When `source: :lucide` the component mimics the helper implementation from
    # the gem:
    #
    #   options = options.with_indifferent_access
    #   size    = options.delete(:size)
    #   options = options.merge width: size, height: size if size
    #
    #   content_tag(:svg, IconProvider.icon(named).html_safe,
    #               LucideRails.default_options.merge(**options))
    #
    # The Phlex version uses `tag.svg` and `text` instead of `content_tag`.
    class Icon < Components::Base
      # @param name [Symbol,String] logical name of the icon (e.g. :home, 'user')
      # @param source [Symbol] icon source provider, currently only :lucide
      # @param options [Hash] HTML attributes passed to the generated <svg>
      def initialize(name, source: :lucide, **options)
        @name = name
        @source = source
        @options = options.with_indifferent_access
      end

      def view_template
        case @source.to_sym
        when :lucide
          render_lucide
        else
          # unknown source, render nothing so we don't break markup
          # future providers could be added here
        end
      end

      private

      def render_lucide
        opts = @options
        size = opts.delete(:size)
        opts.merge!(width: size, height: size) if size

        sanitized_name = @name.to_s.downcase.tr("_", "-")

        inner = LucideRails::IconProvider.icon(sanitized_name)

        svg(**LucideRails.default_options.merge(**opts)) do
          raw safe(inner)
        end
      end
    end
  end
end
