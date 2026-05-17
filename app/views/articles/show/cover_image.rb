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
          div(class: "group w-full overflow-hidden rounded-2xl border border-border shadow-sm") do
            image_tag(
              @presenter.cover_image,
              alt: @presenter.title,
              class: "w-full aspect-[2/1] object-cover grayscale opacity-80 transition-all duration-700 ease-in-out group-hover:scale-105 group-hover:grayscale-0 group-hover:opacity-100 md:aspect-[21/9]"
            )
          end

          return unless @presenter.cover_image_caption.present?

          figcaption(class: "mx-auto mt-3 max-w-2xl text-center text-sm text-muted-foreground") do
            @presenter.cover_image_caption
          end
        end
      end
    end
  end
end
