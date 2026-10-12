# frozen_string_literal: true

# shadcn SheetHeader.
class Components::V2::Sheet::Header < Components::V2::Base
  def initialize(**attrs)
    @attrs = attrs
    super()
  end

  def view_template(&)
    div(**merge_attrs({ class: "flex flex-col gap-1.5 p-4", data: { slot: "sheet-header" } }, @attrs), &)
  end
end
