# frozen_string_literal: true

include Phlex::Rails::Helpers::ContentFor

module Views
  module DesignSystem
    # Index of every ported Chadcn component, read from the gem's packaged catalog (see Components::Parity::Catalog).
    class V2Catalog < Views::Base
      include Phlex::Rails::Helpers::ImagePath

      UPSTREAM_URL = "https://ui.shadcn.com"
      # Wordmark file variant -> classes that show it only in its own theme (the `.dark` class switches).
      WORDMARK_VARIANTS = { "light" => "h-12 w-auto dark:hidden", "dark" => "hidden h-12 w-auto dark:block" }.freeze
      # Stands in for the upstream link inside a translated sentence, so each sentence stays one key per locale.
      UPSTREAM_SLOT = "\u0000"
      # Intrinsic size of the BRAND.md wordmark SVGs, so the browser reserves the box.
      WORDMARK_SIZE = { width: 352, height: 96 }.freeze

      def initialize(entries: Components::Parity::Catalog.entries)
        @entries = entries
        super()
      end

      def view_template
        content_for :page_title, t("design_system.catalog_v2.page_title")
        content_for :head do
          tag(:meta, name: "turbo-cache-control", content: "no-cache")
          tag(:meta, name: "turbo-visit-control", content: "reload")
        end

        div(class: "min-h-screen bg-background text-foreground") do
          header_section
          div(class: "max-w-7xl mx-auto px-4 py-8 lg:grid lg:grid-cols-[14rem_1fr] lg:gap-8") do
            nav_section
            main(class: "min-w-0 space-y-8") { @entries.each { |entry| entry_card(entry) } }
          end
          footer_section
        end
      end

      private

      def header_section
        header(class: "border-b border-border bg-card") do
          div(class: "max-w-7xl mx-auto px-4 py-6 flex items-center justify-between gap-4") do
            div do
              wordmark
              p(class: "text-sm font-medium mt-2") { upstream_sentence("design_system.brand.tagline") }
              h1(class: "text-3xl font-bold mt-4") { t("design_system.catalog_v2.title") }
              p(class: "text-muted-foreground mt-2") { upstream_sentence("design_system.catalog_v2.subtitle", count: @entries.size) }
            end
            div(class: "flex items-center gap-4") do
              link_to(t("design_system.catalog_v2.back"), design_system_path, class: "text-sm underline underline-offset-4")
              render Components::Shared::ThemeToggle.new
            end
          end
        end
      end

      # Light and dark variants of the brand guide's wordmark; the theme's `.dark` class picks one (BRAND.md, Assets).
      def wordmark
        alt = t("design_system.brand.wordmark_alt")
        WORDMARK_VARIANTS.each do |variant, classes|
          img(src: image_path("brand/wordmark-#{variant}.svg"), alt:, **WORDMARK_SIZE, class: classes)
        end
      end

      def footer_section
        footer(class: "border-t border-border") do
          p(class: "max-w-7xl mx-auto px-4 py-6 text-xs text-muted-foreground") do
            upstream_sentence("design_system.brand.disclaimer")
          end
        end
      end

      # A translated sentence whose %{upstream} slot becomes the shadcn/ui link (BRAND.md: link on first mention).
      def upstream_sentence(key, **interpolations)
        lead_in, slot, trailing_text = t(key, **interpolations, upstream: UPSTREAM_SLOT).partition(UPSTREAM_SLOT)
        plain lead_in
        unless slot.empty?
          link_to(t("design_system.brand.upstream_name"), UPSTREAM_URL, class: "underline underline-offset-4")
        end
        plain trailing_text
      end

      def nav_section
        nav(aria_label: t("design_system.catalog_v2.nav"), class: "hidden lg:block sticky top-4 self-start max-h-[calc(100vh-2rem)] overflow-auto") do
          ul(class: "space-y-1 text-sm") do
            @entries.each do |entry|
              li { a(href: "##{entry.anchor}", class: "block rounded-md px-2 py-1 hover:bg-muted") { entry.title } }
            end
          end
        end
      end

      def entry_card(entry)
        section(id: entry.anchor, class: "scroll-mt-4 rounded-lg border border-border bg-card text-card-foreground") do
          div(class: "flex flex-wrap items-baseline justify-between gap-2 border-b border-border px-6 py-4") do
            h2(class: "text-xl font-semibold") { entry.title }
            p(class: "text-xs text-muted-foreground") do
              plain t("design_system.catalog_v2.scenario", id: entry.scenario_id, count: entry.scenario_count)
            end
          end
          # contain-layout makes this box the containing block of fixed descendants (sidebar, sheet triggers' layers stay in it).
          div(class: "p-6 overflow-auto max-h-[32rem] contain-layout") { preview(entry) }
        end
      end

      def preview(entry)
        render Chadcn::Catalog::TreeRenderer.new(tree: entry.tree, component: entry.component)
      rescue StandardError => e
        Rails.logger.error("[design-system v2] #{entry.component}: #{e.class}: #{e.message}")
        p(class: "text-sm text-destructive") { t("design_system.catalog_v2.unavailable", error: e.class.name) }
      end
    end
  end
end
