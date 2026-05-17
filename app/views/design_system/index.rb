# frozen_string_literal: true

include Phlex::Rails::Helpers::ContentFor

module Views
  module DesignSystem
    class Index < Views::Base
      def view_template
        content_for :head do
          tag(:meta, name: "turbo-cache-control", content: "no-cache")
          tag(:meta, name: "turbo-visit-control", content: "reload")
        end

        div(class: "min-h-screen bg-background text-foreground") do
          div(data: { controller: "design-system" }) do
            render Index::Header.new
            render Index::CategoryNav.new

            main(class: "max-w-7xl mx-auto px-4 py-8") do
              render Index::FoundationSection.new
              render Index::FormsSection.new
              render Index::FeedbackSection.new
              render Index::OverlaysSection.new
              render Index::TablesSection.new
              render Index::ComplexSection.new
              render Index::StatusPanel.new
            end
          end
        end
      end
    end
  end
end
