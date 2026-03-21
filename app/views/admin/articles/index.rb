# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index < Views::Base
        def initialize(articles)
          @articles = articles
        end

        def view_template
          turbo_frame_tag "admin_articles_list" do
            div(class: "bg-background") do
              div(class: "mx-auto max-w-6xl px-4 py-8") do
                render_breadcrumb
                render Components::Ui::Card.new do
                  render_header
                  render_articles
                end
              end
            end
          end
        end

        private

        def render_breadcrumb
          render Components::Ui::Breadcrumb.new(class: "mb-6") do
            render Components::Ui::BreadcrumbList.new do
              render Components::Ui::BreadcrumbItem.new do
                render Components::Ui::BreadcrumbLink.new(href: admin_root_path) { t("admin.articles.breadcrumbs.home") }
              end
              render Components::Ui::BreadcrumbSeparator.new
              render Components::Ui::BreadcrumbItem.new do
                render Components::Ui::BreadcrumbPage.new { t("admin.articles.breadcrumbs.articles") }
              end
            end
          end
        end

        def render_header
          render Components::Ui::CardHeader.new(class: "flex flex-row items-center justify-between space-y-0") do
            div do
              render Components::Ui::CardTitle.new(as: :h1) { t("admin.articles.index.title") }
              render Components::Ui::CardDescription.new { t("admin.articles.index.subtitle") }
            end

            render Components::Ui::Button.new(
              as: :a,
              href: new_admin_article_path,
              data: { turbo_frame: "_top" }
            ) { t("admin.articles.index.new_article") }
          end
        end

        def render_articles
          render Components::Ui::CardContent.new() do
            if @articles.empty?
              div(class: "text-center py-12 px-6") do
                svg(class: "mx-auto h-12 w-12 text-muted-foreground mb-4", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                  s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "1.5", d: "M19 12H5m7-7v14")
                end
                p(class: "text-base font-medium") { t("admin.articles.index.empty_title") }
                p(class: "text-sm text-muted-foreground mt-1") { t("admin.articles.index.empty_description") }
              end
            else
              render Components::Ui::TableContainer.new do
                render Components::Ui::Table.new do
                  render Components::Ui::TableHeader.new do
                    render Components::Ui::TableRow.new do
                      render Components::Ui::TableHead.new { t("admin.articles.index.columns.article") }
                      render Components::Ui::TableHead.new { t("admin.articles.index.columns.status") }
                      render Components::Ui::TableHead.new { t("admin.articles.index.columns.published") }
                      render Components::Ui::TableHead.new { t("admin.articles.index.columns.excerpt") }
                      render Components::Ui::TableHead.new(class: "text-right") { t("admin.articles.index.columns.actions") }
                    end
                  end

                  render Components::Ui::TableBody.new do
                    @articles.each do |article|
                      render_article_row(article)
                    end
                  end
                end
              end
            end
          end
        end

        def render_article_row(article)
          render Components::Ui::TableRow.new do
            render Components::Ui::TableCell.new(class: "font-medium") do
              article.title
            end

            render Components::Ui::TableCell.new do
              render Components::Ui::Badge.new(variant: status_variant(article)) do
                t("admin.articles.index.statuses.#{article.status}")
              end
            end

            render Components::Ui::TableCell.new(class: "text-sm text-muted-foreground") do
              if article.published_at
                I18n.l(article.published_at, format: :short)
              else
                t("admin.articles.index.not_published")
              end
            end

            render Components::Ui::TableCell.new(class: "text-sm text-muted-foreground") do
              if article.excerpt.present?
                span(class: "block line-clamp-2 max-w-[36ch]") { article.excerpt }
              else
                span(class: "italic") { t("admin.articles.index.no_excerpt") }
              end
            end

            render Components::Ui::TableCell.new(class: "text-right") do
              div(data: { controller: "ui--dropdown", ui__dropdown_placement_value: "bottom-end" }) do
                render Components::Ui::Button.new(
                  variant: :ghost,
                  size: :icon,
                  class: "size-8",
                  data: { action: "click->ui--dropdown#toggle", ui__dropdown_target: "trigger" }
                ) do
                  render Components::Ui::Icon.new(:"more-horizontal", class: "h-4 w-4")
                  span(class: "sr-only") { t("admin.articles.index.menu_trigger") }
                end

                render Components::Ui::DropdownMenuContent.new(
                  hidden: true,
                  align: :end,
                  data: {
                    ui__dropdown_target: "content",
                    action: "keydown->ui--dropdown#navigate"
                  }
                ) do
                  render_action_menu_item(
                    label: t("admin.articles.index.edit"),
                    href: edit_admin_article_path(article)
                  )

                  if article.status_published?
                    render_action_menu_item(
                      label: t("admin.articles.index.show"),
                      href: article_path(article),
                      target: "_blank"
                    )
                  end

                  if article.status_draft?
                    render_action_menu_item(
                      label: t("admin.articles.index.publish"),
                      href: publish_admin_article_path(article, publish_action: "publish"),
                      method: :patch
                    )
                  elsif article.status_published?
                    render_action_menu_item(
                      label: t("admin.articles.index.unpublish"),
                      href: publish_admin_article_path(article, publish_action: "unpublish"),
                      method: :patch
                    )
                  end

                  render Components::Ui::DropdownMenuSeparator.new

                  render_action_menu_item(
                    label: t("admin.articles.index.delete"),
                    href: admin_article_path(article),
                    method: :delete,
                    confirm: t("admin.articles.index.confirm_delete"),
                    variant: :destructive
                  )
                end
              end
            end
          end
        end

        def render_action_menu_item(label:, href:, method: nil, confirm: nil, variant: :default, target: nil)
          data_attrs = {
            ui__dropdown_target: "item",
            action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown",
            turbo_frame: "_top"
          }
          data_attrs[:turbo_method] = method if method
          data_attrs[:turbo_confirm] = confirm if confirm

          render Components::Ui::DropdownMenuItem.new(
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
