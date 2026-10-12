# frozen_string_literal: true

# shadcn SheetFooter.
class Components::V2::Sheet::Footer < Components::V2::Base
  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    div(**merge_attrs({ class: "mt-auto flex flex-col gap-2 p-4", data: { slot: "sheet-footer" } }, @attrs), &)
  end
end
