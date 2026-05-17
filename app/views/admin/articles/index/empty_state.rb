# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index::EmptyState < Views::Base
        def view_template
          div(class: "text-center py-12 px-6") do
            render Components::Ui::Icon.new(:plus, class: "mx-auto h-12 w-12 text-muted-foreground mb-4")
            p(class: "text-base font-medium") { t("admin.articles.index.empty_title") }
            p(class: "text-sm text-muted-foreground mt-1") { t("admin.articles.index.empty_description") }
          end
        end
      end
    end
  end
end
