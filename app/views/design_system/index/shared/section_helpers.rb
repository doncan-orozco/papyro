# frozen_string_literal: true

module Views
  module DesignSystem
    module Index::Shared::SectionHelpers
      private

      def section_container(id:, hidden: true, &block)
        classes = [ "space-y-8" ]
        classes << "hidden" if hidden

        div(
          class: classes.join(" "),
          data: {
            design_system_target: "category",
            category: id
          },
          &block
        )
      end

      def component_card(title:, description:, &block)
        render Components::Ui::Card.new(class: "mb-6") do |card|
          card.header do
            card.title { title }
            card.description { description }
          end

          card.content(class: "space-y-4", &block)
        end
      end
    end
  end
end
