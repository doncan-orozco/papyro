# Lucide icon, rendered like lucide-react 0.577.0 (see icons/catalog.rb).
# No default size class, like lucide-react (width/height 24): shadcn components size icons via parent selectors
# such as `[&_svg:not([class*='size-'])]:size-4`, which need the icon to carry no `size-*` class of its own.
class Components::V2::Icon < Components::V2::Base
  def initialize(name, **attrs)
    @name = name.to_s
    @attrs = attrs
    super()
  end

  def view_template
    key = Components::V2::Icons::Catalog::ALIASES.fetch(@name) { normalize(@name) }
    nodes = Components::V2::Icons::Catalog::NODES.fetch(key) do
      raise ArgumentError, "unknown icon #{@name.inspect}"
    end

    svg(**merge_attrs(default_attrs(key), @attrs)) { raw(safe(nodes)) }
  end

  private

  def normalize(name)
    name.tr("_", "-").delete_suffix("-icon")
  end

  def default_attrs(key)
    {
      xmlns: "http://www.w3.org/2000/svg",
      width: 24,
      height: 24,
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      stroke_width: 2,
      stroke_linecap: "round",
      stroke_linejoin: "round",
      class: Components::V2::Icons::Catalog::CLASSES.fetch(key) { "lucide lucide-#{key}" },
      aria: { hidden: "true" }
    }
  end
end
