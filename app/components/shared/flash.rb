# frozen_string_literal: true

module Components
  module Shared
    class Flash < Components::Base
      def initialize(flash:, **attrs)
        @flash = flash
        @attrs = attrs
      end

      def view_template
        return if messages.empty?

        div(class: merged_classes, **attrs_without_class) do
          div(class: "space-y-3") do
            messages.each do |type, message|
              render_flash(type, message)
            end
          end
        end
      end

      private

      def classes
        "fixed top-4 left-1/2 z-50 w-full max-w-2xl -translate-x-1/2 px-4"
      end

      def messages
        @messages ||= [
          [ :notice, @flash[:notice] ],
          [ :alert, @flash[:alert] ]
        ].flat_map do |type, value|
          Array(value).compact_blank.map { |message| [ type, message ] }
        end
      end

      def render_flash(type, message)
        case type
        when :notice
          render Components::Ui::Alert.new(class: "border-green-600 bg-green-50 text-green-900") do
            svg(class: "h-5 w-5 text-green-600", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 12l2 2m0 0l4-4m-16 6v7a2 2 0 002 2h12a2 2 0 002-2v-7")
            end
            p { message }
          end
        when :alert
          render Components::Ui::Alert.new(variant: :destructive) do |alert|
            svg(class: "h-5 w-5", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M12 8v4m0 4v.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
            end
            alert.description do
              p(class: "font-semibold") { message }
            end
          end
        end
      end
    end
  end
end
