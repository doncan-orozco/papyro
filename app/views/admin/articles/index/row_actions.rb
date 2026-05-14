# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index::RowActions < Views::Base
        def initialize(article:)
          @article = article
        end

        def view_template
          render Components::Ui::DropdownMenu.new(data: { ui__dropdown_placement_value: "bottom-end" }) do |dropdown|
            render_trigger(dropdown)
            render_content(dropdown)
          end
        end

        private

        def render_trigger(dropdown)
          dropdown.trigger(variant: :ghost, size: :icon, class: "size-8") do
            render Components::Ui::Icon.new(:"more-horizontal", class: "h-4 w-4")
            span(class: "sr-only") { t("admin.articles.index.menu_trigger") }
          end
        end

        def render_content(dropdown)
          dropdown.content(hidden: true, align: :end) do
            render_action_menu_item(
              dropdown: dropdown,
              label: t("admin.articles.index.edit"),
              href: edit_article_path(@article)
            )

            if @article.published?
              render_action_menu_item(
                dropdown: dropdown,
                label: t("admin.articles.index.show"),
                href: article_path(@article),
                target: "_blank"
              )
            end

            if @article.draft?
              render_action_menu_item(
                dropdown: dropdown,
                label: t("admin.articles.index.publish"),
                href: publish_article_path(@article, publish_action: "publish"),
                method: :patch
              )
            elsif @article.published?
              render_action_menu_item(
                dropdown: dropdown,
                label: t("admin.articles.index.unpublish"),
                href: publish_article_path(@article, publish_action: "unpublish"),
                method: :patch
              )
            end

            dropdown.separator

            render_action_menu_item(
              dropdown: dropdown,
              label: t("admin.articles.index.delete"),
              href: article_path(@article),
              method: :delete,
              confirm: t("admin.articles.index.confirm_delete"),
              variant: :destructive
            )
          end
        end

        def render_action_menu_item(dropdown:, label:, href:, method: nil, confirm: nil, variant: :default, target: nil)
          data_attrs = { turbo_frame: "_top" }
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
      end
    end
  end
end
