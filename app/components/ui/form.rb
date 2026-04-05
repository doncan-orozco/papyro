# frozen_string_literal: true

# Form - form wrapper with validation display
# Following shadcn/ui Radix patterns with semantic tokens
module Components
  module Ui
    # Form root container
    class Form < Components::Base
      def initialize(action: nil, method: :post, **attrs)
        @action = action
        @method = method
        @attrs = attrs
      end

      def view_template(&block)
        form(
          action: @action,
          method: @method,
          class: merged_classes,
          **attrs_without_class,
        ) do
          yield self if block
        end
      end

      def item(**attrs, &block)
        render Item.new(**attrs), &block
      end

      def label(**attrs, &block)
        render Label.new(**attrs), &block
      end

      def control(**attrs, &block)
        render Control.new(**attrs), &block
      end

      def description(**attrs, &block)
        render Description.new(**attrs), &block
      end

      def message(**attrs, &block)
        render Message.new(**attrs), &block
      end

      private

      def classes
        "space-y-6"
      end
    end

    # Form Item - individual form field wrapper
    class Form::Item < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "space-y-2"
      end
    end

    # Form Label - label for form fields
    class Form::Label < Components::Base
      def initialize(for_id: nil, **attrs)
        @for_id = for_id
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        dynamic_attrs[:for] = @for_id if @for_id

        label(
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "text-sm font-medium leading-none",
          "peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
        ].join(" ")
      end
    end

    # Form Control - wrapper for form inputs
    class Form::Control < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Form Description - help text for form fields
    class Form::Description < Components::Base
      def view_template(&block)
        p(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm text-muted-foreground"
      end
    end

    # Form Message - validation error message
    class Form::Message < Components::Base
      def view_template(&block)
        p(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm font-medium text-destructive"
      end
    end

    FormItem = Form::Item
    FormLabel = Form::Label
    FormControl = Form::Control
    FormDescription = Form::Description
    FormMessage = Form::Message
  end
end
