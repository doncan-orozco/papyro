# frozen_string_literal: true

# shadcn SheetDescription. Marks the sheet as described so Content can emit aria-describedby.
class Components::V2::Sheet::Description < Components::V2::Base
  include Components::V2::Sheet::Support

  def initialize(as_child: false, **attrs)
    @as_child = as_child
    @attrs = attrs
    super()
  end

  def view_template(&)
    root = root_context
    root[:description_present] = true
    attrs = merge_attrs({ id: root[:description_id], class: "text-sm text-muted-foreground", data: { slot: "sheet-description" } }, @attrs)
    render_part(:p, @as_child, attrs, &)
  end
end
