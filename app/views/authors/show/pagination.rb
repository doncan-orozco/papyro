# frozen_string_literal: true

module Views
  module Authors
    class Show::Pagination < Views::Base
      def initialize(pagy:, username:)
        @pagy = pagy
        @username = username
      end

      def view_template
        render Components::Ui::Pagination.new do |pagination|
          pagination.content do
            pagination.item do
              pagination.previous(
                href: (@pagy.previous ? "/@#{@username}?page=#{@pagy.previous}" : nil)
              ) { t("design_system.pagination.previous") }
            end

            @pagy.send(:series).each do |page_item|
              pagination.item do
                case page_item
                when Integer
                  pagination.link(href: "/@#{@username}?page=#{page_item}") { page_item }
                when String
                  pagination.link(active: true) { page_item }
                when :gap
                  pagination.ellipsis
                end
              end
            end

            pagination.item do
              pagination.next(
                href: (@pagy.next ? "/@#{@username}?page=#{@pagy.next}" : nil)
              ) { t("design_system.pagination.next") }
            end
          end
        end
      end
    end
  end
end
