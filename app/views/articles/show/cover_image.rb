# frozen_string_literal: true

module Views
  module Articles
    class Show::CoverImage < Views::Base
      include Phlex::Rails::Helpers::ImageTag

      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        return unless @presenter.cover_image_attached?

        figure(class: "mt-8 mb-12 flex w-full flex-col items-center") do
          image_tag(
            @presenter.cover_image,
            alt: @presenter.title,
            class: "w-full aspect-[2/1] rounded-2xl border border-border object-cover shadow-sm md:aspect-[21/9]"
          )

          return unless @presenter.cover_image_caption.present?

          figcaption(class: "mx-auto mt-3 max-w-2xl text-center text-sm text-muted-foreground") do
            @presenter.cover_image_caption
          end
        end
      end
    end
  end
end
