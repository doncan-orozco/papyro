# frozen_string_literal: true

module Views
  module Authors
    class Show < Views::Base
      def initialize(author:, profile:, articles:, pagy:)
        @author = author
        @profile = profile
        @articles = articles
        @pagy = pagy
      end

      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new
          main(class: "mx-auto w-full max-w-4xl px-4 py-10 space-y-10") do
            render_identity_header
            render_articles_section
          end
        end
      end

      private

      def render_identity_header
        div(class: "flex flex-col md:flex-row items-start gap-6 md:gap-8 mb-16") do
          div(
            class: "h-24 w-24 shrink-0 rounded-full border border-border bg-muted flex items-center justify-center text-3xl font-bold text-muted-foreground select-none",
            aria: { hidden: "true" }
          ) { @profile.display_name.first.upcase }

          div(class: "min-w-0 flex-1") do
            div(class: "flex flex-col md:flex-row md:items-start justify-between gap-4") do
              div(class: "space-y-1") do
                h1(class: "text-3xl font-extrabold tracking-tight") { @profile.display_name }
                p(class: "text-sm text-muted-foreground") { "@#{@profile.username}" }
              end

              if owner?
                render Components::Ui::Button.new(
                  as: :a,
                  href: edit_settings_profile_path,
                  variant: :outline,
                  size: :sm,
                  class: "w-fit",
                  data: { turbo_frame: "_top" }
                ) { t("authors.show.edit_profile") }
              end
            end

            if @profile.bio.present?
              p(class: "mt-4 text-base leading-relaxed max-w-2xl text-foreground/90") { @profile.bio }
            end

            render_meta_and_social_links if any_meta_or_social?
          end
        end
      end

      def render_meta_and_social_links
        div(class: "mt-4 flex flex-wrap items-center gap-4 text-sm text-muted-foreground") do
          if @profile.location.present?
            div(class: "inline-flex items-center gap-1.5") do
              render Components::Ui::Icon.new(:map_pin, class: "size-4 shrink-0")
              span { @profile.location }
            end
          end

          if @profile.website_url.present?
            a(
              href: @profile.website_url,
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex items-center gap-1.5 hover:text-foreground transition-colors"
            ) do
              render Components::Ui::Icon.new(:link, class: "size-4 shrink-0")
              span(class: "truncate max-w-[180px]") { t("authors.show.website") }
            end
          end

          if @profile.x_handle.present?
            link_to(
              "https://x.com/#{@profile.x_handle.delete_prefix('@')}",
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex items-center gap-1.5 hover:text-foreground transition-colors"
            ) do
              render Components::Ui::Icon.new(:twitter, class: "size-3.5")
              span(class: "font-medium") { "@#{@profile.x_handle.delete_prefix('@')}" }
            end
          end

          if @profile.linkedin_handle.present?
            link_to(
              "https://linkedin.com/in/#{@profile.linkedin_handle}",
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex items-center gap-1.5 hover:text-foreground transition-colors"
            ) do
              render Components::Ui::Icon.new(:linkedin, class: "size-4 shrink-0")
              span { t("authors.show.linkedin") }
            end
          end
        end
      end

      def render_articles_section
        div(class: "space-y-6") do
          h2(class: "text-xl font-semibold tracking-tight") { t("authors.show.articles_by", name: @profile.display_name) }

          if @articles.empty?
            div(class: "rounded-lg border border-dashed border-border py-16 text-center") do
              p(class: "text-muted-foreground text-sm") { t("authors.show.no_articles") }
            end
          else
            div(class: "grid grid-cols-1 gap-5 sm:grid-cols-2") do
              @articles.each do |article|
                render Components::Landing::ArticleCard.new(
                  article: article
                )
              end
            end

            render_pagination if @pagy.pages > 1
          end
        end
      end

      def render_pagination
        render Components::Ui::Pagination.new do |pagination|
          pagination.content do
            pagination.item do
              pagination.previous(
                href: (@pagy.previous ? "/@#{@profile.username}?page=#{@pagy.previous}" : nil)
              ) { t("design_system.pagination.previous") }
            end

            @pagy.send(:series).each do |page_item|
              pagination.item do
                case page_item
                when Integer
                  pagination.link(href: "/@#{@profile.username}?page=#{page_item}") { page_item }
                when String
                  pagination.link(active: true) { page_item }
                when :gap
                  pagination.ellipsis
                end
              end
            end

            pagination.item do
              pagination.next(
                href: (@pagy.next ? "/@#{@profile.username}?page=#{@pagy.next}" : nil)
              ) { t("design_system.pagination.next") }
            end
          end
        end
      end

      def any_meta_or_social?
        @profile.location.present? || @profile.website_url.present? || @profile.x_handle.present? || @profile.linkedin_handle.present?
      end

      def owner?
        Current.user.registered? && Current.user.id == @author.id
      end
    end
  end
end
