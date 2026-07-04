# frozen_string_literal: true

module Components
  module Public
    class SearchForm < Components::Base
      def initialize(frame_id: "search_results", **attrs)
        @frame_id = frame_id
        @attrs = attrs
      end

      def view_template
        div(
          data: { controller: "search" },
          class: merged_classes,
          **attrs_without_class
        ) do
          form(
            data: { search_target: "form", turbo_frame: @frame_id },
            action: search_path,
            method: "get",
            class: "w-full"
          ) do
            div(class: "flex h-10 items-center gap-2 rounded-full border border-border bg-card/80 px-4 text-sm shadow-sm") do
              render Components::Ui::Icon.new(:search, class: "h-4 w-4 shrink-0 text-foreground/80")
              input(
                data: {
                  search_target: "input",
                  action: "input->search#search keydown->search#handleEscape"
                },
                type: "search",
                name: "q",
                placeholder: t("articles.index.search_placeholder"),
                autocomplete: "off",
                spellcheck: "false",
                class: "flex-1 bg-transparent outline-none placeholder:text-foreground/40"
              )
            end
          end

          div(
            data: { search_target: "panel" },
            class: "hidden absolute left-0 right-0 top-full mt-2 z-50 rounded-lg border border-border bg-card shadow-lg overflow-hidden"
          ) do
            turbo_frame_tag @frame_id.to_sym, data: { search_target: "results" }, class: "block"
          end
        end
      end

      private

      def classes
        "relative w-full"
      end
    end
  end
end
