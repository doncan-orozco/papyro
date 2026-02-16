# frozen_string_literal: true

module Components
  module Ui
    class Card < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "rounded-lg border border-slate-200 bg-white text-slate-950 shadow-sm",
          **@attrs,
          &block
        )
      end
    end

    class CardHeader < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "flex flex-col space-y-1.5 p-6",
          **@attrs,
          &block
        )
      end
    end

    class CardTitle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h3(
          class: "text-2xl font-semibold leading-none tracking-tight",
          **@attrs,
          &block
        )
      end
    end

    class CardDescription < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        p(
          class: "text-sm text-slate-500",
          **@attrs,
          &block
        )
      end
    end

    class CardContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "p-6 pt-0",
          **@attrs,
          &block
        )
      end
    end

    class CardFooter < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: "flex items-center p-6 pt-0",
          **@attrs,
          &block
        )
      end
    end
  end
end
