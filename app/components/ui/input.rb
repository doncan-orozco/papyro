# frozen_string_literal: true

module Components
  module Ui
    class Input < Components::Base
      def initialize(type: "text", placeholder: nil, required: false, autofocus: false, autocomplete: nil, value: nil, name: nil, id: nil, maxlength: nil, rows: nil, **attrs)
        @type = type
        @placeholder = placeholder
        @required = required
        @autofocus = autofocus
        @autocomplete = autocomplete
        @value = value
        @name = name
        @id = id
        @maxlength = maxlength
        @rows = rows
        @attrs = attrs
      end

      def view_template
        if @type == "textarea"
          textarea(
            name: @name,
            id: @id,
            placeholder: @placeholder,
            required: @required,
            autofocus: @autofocus,
            autocomplete: @autocomplete,
            maxlength: @maxlength,
            rows: @rows,
            class: classes,
            **@attrs
          ) { @value }
        else
          input(
            type: @type,
            name: @name,
            id: @id,
            placeholder: @placeholder,
            required: @required,
            autofocus: @autofocus,
            autocomplete: @autocomplete,
            value: @value,
            maxlength: @maxlength,
            class: classes,
            **@attrs
          )
        end
      end

      private

      def classes
        "flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
      end
    end
  end
end
