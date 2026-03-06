# frozen_string_literal: true

include Phlex::Rails::Helpers::ContentFor
include Phlex::Rails::Helpers::Routes

module Views
  module DesignSystem
    class Compare < Views::Base
      def view_template
        content_for :head do
          tag(:meta, name: "turbo-cache-control", content: "no-cache")
          tag(:meta, name: "turbo-visit-control", content: "reload")
        end

        div(class: "min-h-screen bg-background text-foreground font-['Manrope']") do
          header(class: "border-b border-border bg-card/50 sticky top-0 z-40") do
            div(class: "max-w-full mx-auto px-6 py-4 lg:px-10") do
              div(class: "flex items-center justify-between") do
                h1(class: "text-xl font-bold") { "Component Comparison: React vs Phlex" }
                
                nav(class: "flex gap-2 text-sm") do
                  link_to(
                    "← Phlex Catalog",
                    design_system_path,
                    class: "px-3 py-2 rounded-lg hover:bg-muted transition-colors"
                  )
                  link_to(
                    "React Catalog →",
                    design_system_react_path,
                    class: "px-3 py-2 rounded-lg hover:bg-muted transition-colors"
                  )
                end
              end
            end
          </header>

          # Split-screen layout
          div(class: "grid grid-cols-2 gap-0 h-[calc(100vh-65px)] overflow-hidden") do
            # Left side: React catalog
            div(class: "border-r border-border overflow-hidden") do
              div(class: "h-full flex flex-col") do
                div(class: "bg-muted/50 px-4 py-3 border-b border-border") do
                  p(class: "text-sm font-medium") { "React shadcn/ui (Source of Truth)" }
                end
                
                iframe(
                  src: "/react-catalog/",
                  title: "React shadcn/ui Components",
                  class: "flex-1 border-0 w-full",
                  allow: "same-origin"
                )
              end
            end

            # Right side: Phlex catalog
            div(class: "overflow-hidden") do
              div(class: "h-full flex flex-col") do
                div(class: "bg-muted/50 px-4 py-3 border-b border-border") do
                  p(class: "text-sm font-medium") { "Phlex Components (Implementation)" }
                end
                
                iframe(
                  src: design_system_path,
                  title: "Phlex Design System Components",
                  class: "flex-1 border-0 w-full",
                  allow: "same-origin"
                )
              end
            end
          end

          # Keyboard shortcuts hint
          div(class: "fixed bottom-4 right-4 px-3 py-2 bg-muted/80 rounded-lg text-xs text-muted-foreground pointer-events-none") do
            "💡 Open both side panels to pixel-compare components"
          end
        end
      end
    end
  end
end
