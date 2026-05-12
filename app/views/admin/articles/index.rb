# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index < Views::Base
        def initialize(articles:)
          @articles = articles
        end

        def view_template
          turbo_frame_tag "admin_articles_list" do
            div(class: "bg-background") do
              div(class: "mx-auto max-w-6xl px-4 py-8") do
                render_breadcrumb
                render Components::Ui::Card.new do |card|
                  render_header(card)
                  render_articles(card)
                end
              end
            end
          end
        end

        private

        def render_breadcrumb
          render Components::Ui::Breadcrumb.new(class: "mb-6") do |breadcrumb|
            breadcrumb.list do
              breadcrumb.item do
                breadcrumb.link(href: mine_articles_path) { t("admin.articles.breadcrumbs.home") }
              end
              breadcrumb.separator
              breadcrumb.item do
                breadcrumb.page { t("admin.articles.breadcrumbs.articles") }
              end
            end
          end
        end

        def render_header(card)
          card.header(class: "flex flex-row items-center justify-between space-y-0") do
            div do
              card.title(as: :h1) { t("admin.articles.index.title") }
              card.description { t("admin.articles.index.subtitle") }
            end

            render Components::Ui::Button.new(
              as: :a,
              href: new_article_path,
              data: { turbo_frame: "_top" }
            ) { t("admin.articles.index.new_article") }
          end
        end

        def render_articles(card)
          card.content do
            if @articles.empty?
              div(class: "text-center py-12 px-6") do
                render Components::Ui::Icon.new(:plus, class: "mx-auto h-12 w-12 text-muted-foreground mb-4")
                p(class: "text-base font-medium") { t("admin.articles.index.empty_title") }
                p(class: "text-sm text-muted-foreground mt-1") { t("admin.articles.index.empty_description") }
              end
            else
              render Components::Ui::Table.new do |table|
                table.header do
                  table.row do
                    table.head { t("admin.articles.index.columns.article") }
                    table.head { t("admin.articles.index.columns.status") }
                    table.head { t("admin.articles.index.columns.published") }
                    table.head { t("admin.articles.index.columns.excerpt") }
                    table.head(class: "text-right") { t("admin.articles.index.columns.actions") }
                  end
                end

                table.body do
                  @articles.each do |article|
                    render_article_row(table, article)
                  end
                end
              end
            end
          end
        end

        def render_article_row(table, article)
          table.row do
            table.cell(class: "font-medium") do
              article.title
            end

            table.cell do
              render Components::Ui::Badge.new(variant: status_variant(article)) do
                t("admin.articles.index.statuses.#{article.status}")
              end
            end

            table.cell(class: "text-sm text-muted-foreground") do
              if article.published_at
                I18n.l(article.published_at, format: :short)
              else
                t("admin.articles.index.not_published")
              end
            end

            table.cell(class: "text-sm text-muted-foreground") do
              if article.excerpt.present?
                span(class: "block line-clamp-2 max-w-[36ch]") { article.excerpt }
              else
                span(class: "italic") { t("admin.articles.index.no_excerpt") }
              end
            end

            table.cell(class: "text-right") do
              render Components::Ui::DropdownMenu.new(
                data: { ui__dropdown_placement_value: "bottom-end" }
              ) do |dropdown|
                dropdown.trigger(
                  variant: :ghost,
                  size: :icon,
                  class: "size-8"
                ) do
                  render Components::Ui::Icon.new(:"more-horizontal", class: "h-4 w-4")
                  span(class: "sr-only") { t("admin.articles.index.menu_trigger") }
                end

                dropdown.content(
                  hidden: true,
                  align: :end
                ) do
                  render_action_menu_item(
                    dropdown: dropdown,
                    label: t("admin.articles.index.edit"),
                    href: edit_article_path(article)
                  )

                  if article.published?
                    render_action_menu_item(
                      dropdown: dropdown,
                      label: t("admin.articles.index.show"),
                      href: article_path(article),
                      target: "_blank"
                    )
                  end

                  if article.draft?
                    render_action_menu_item(
                      dropdown: dropdown,
                      label: t("admin.articles.index.publish"),
                      href: publish_article_path(article, publish_action: "publish"),
                      method: :patch
                    )
                  elsif article.published?
                    render_action_menu_item(
                      dropdown: dropdown,
                      label: t("admin.articles.index.unpublish"),
                      href: publish_article_path(article, publish_action: "unpublish"),
                      method: :patch
                    )
                  end

                  dropdown.separator

                  render_action_menu_item(
                    dropdown: dropdown,
                    label: t("admin.articles.index.delete"),
                    href: article_path(article),
                    method: :delete,
                    confirm: t("admin.articles.index.confirm_delete"),
                    variant: :destructive
                  )
                end
              end
            end
          end
        end

        def render_action_menu_item(dropdown:, label:, href:, method: nil, confirm: nil, variant: :default, target: nil)
          data_attrs = {
            turbo_frame: "_top"
          }
          data_attrs[:turbo_method] = method if method
          data_attrs[:turbo_confirm] = confirm if confirm

          dropdown.item(
            href: href,
            variant: variant,
            target: target,
            rel: target == "_blank" ? "noopener noreferrer" : nil,
            data: data_attrs
          ) { label }
        end

        def status_variant(article)
          case article.status
          when "draft" then :secondary
          when "published" then :default
          when "archived" then :outline
          else :secondary
          end
        end
      end
    end
  end
end
