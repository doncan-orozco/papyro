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
          div(class: "w-full max-w-sm space-y-2") do
            messages.each do |type, message|
              render_flash(type, message)
            end
          end
        end
      end

      private

      def classes
        "pointer-events-none fixed inset-x-0 bottom-4 z-[100] flex justify-end px-4 sm:inset-x-auto sm:right-4 sm:px-0"
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
        render Components::Ui::Toast.new(
          variant: toast_variant(type),
          class: "pointer-events-auto",
          data: {
            controller: "toast",
            toast_duration_value: 4000,
            state: "open"
          }
        ) do |toast|
          render_toast_icon(type)

          div(class: "grid gap-1") do
            toast.title { t("app.toasts.#{toast_title_key(type)}") }
            toast.description { message }
          end

          toast.close(data: { action: "toast#dismiss" }, aria: { label: t("app.toasts.close") })
        end
      end

      def render_toast_icon(type)
        if type.to_sym == :alert
          svg(class: "h-5 w-5 shrink-0", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
            s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M12 8v4m0 4v.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
          end
        else
          svg(class: "h-5 w-5 shrink-0", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
            s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z")
          end
        end
      end

      def toast_variant(type)
        type.to_sym == :alert ? :destructive : :default
      end

      def toast_title_key(type)
        type.to_sym == :alert ? "error" : "success"
      end
    end
  end
end
