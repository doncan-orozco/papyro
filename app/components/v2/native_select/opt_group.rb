# frozen_string_literal: true

class Components::V2::NativeSelect
  class OptGroup < Components::V2::Base
    def initialize(**attrs)
      @attrs = attrs
      super()
    end

    def view_template(&)
      optgroup(**merge_attrs({ class: "bg-[Canvas] text-[CanvasText]", data: { slot: "native-select-optgroup" } }, @attrs), &)
    end
  end
end
