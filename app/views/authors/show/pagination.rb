# frozen_string_literal: true

module Views
  module Authors
    class Show::Pagination < Views::Base
      def initialize(pagy:, username:)
        @pagy = pagy
        @username = username
      end

      def view_template
        render Chadcn::Pagination.new do |pagination|
          pagination.content do
            pagination.item do
              pagination.previous(
                label: t("design_system.pagination.previous"),
                href: ("/@#{@username}?page=#{@pagy.previous}" if @pagy.previous),
                aria: { disabled: ("true" unless @pagy.previous) },
                class: ("pointer-events-none opacity-50" unless @pagy.previous)
              )
            end

            @pagy.send(:series).each do |page_item|
              pagination.item do
                case page_item
                when Integer
                  pagination.link(href: "/@#{@username}?page=#{page_item}") { page_item }
                when String
                  pagination.link(is_active: true) { page_item }
                when :gap
                  pagination.ellipsis(label: t("design_system.pagination.more_pages"))
                end
              end
            end

            pagination.item do
              pagination.next(
                label: t("design_system.pagination.next"),
                href: ("/@#{@username}?page=#{@pagy.next}" if @pagy.next),
                aria: { disabled: ("true" unless @pagy.next) },
                class: ("pointer-events-none opacity-50" unless @pagy.next)
              )
            end
          end
        end
      end
    end
  end
end
