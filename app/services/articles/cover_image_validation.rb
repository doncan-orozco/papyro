# frozen_string_literal: true

module Articles
  class CoverImageValidation
    def initialize(article)
      @article = article
    end

    def validate
      return unless @article.cover_image.attached?

      unless @article.class::ALLOWED_COVER_IMAGE_CONTENT_TYPES.include?(@article.cover_image.blob.content_type)
        @article.errors.add(:cover_image, I18n.t("articles.errors.invalid_cover_image_content_type"))
        return
      end

      if @article.cover_image.blob.byte_size > @article.class::MAX_COVER_IMAGE_SIZE
        @article.errors.add(
          :cover_image,
          I18n.t("articles.errors.invalid_cover_image_size", max_size_mb: @article.class::MAX_COVER_IMAGE_SIZE / 1.megabyte)
        )
      end

      width, height = cover_image_dimensions

      if width.blank? || height.blank?
        @article.errors.add(:cover_image, I18n.t("articles.errors.invalid_cover_image_dimensions"))
        return
      end

      return if width >= @article.class::MIN_COVER_IMAGE_WIDTH && height >= @article.class::MIN_COVER_IMAGE_HEIGHT

      @article.errors.add(
        :cover_image,
        I18n.t(
          "articles.errors.cover_image_too_small",
          min_width: @article.class::MIN_COVER_IMAGE_WIDTH,
          min_height: @article.class::MIN_COVER_IMAGE_HEIGHT
        )
      )
    end

    private

    def cover_image_dimensions
      pending_change = @article.attachment_changes["cover_image"]
      pending_attachable = pending_change&.attachable

      if pending_attachable.present?
        dimensions = dimensions_from_attachable(pending_attachable)
        return dimensions if dimensions.compact.size == 2
      end

      @article.cover_image.blob.analyze unless @article.cover_image.blob.analyzed?

      width = @article.cover_image.blob.metadata[:width] || @article.cover_image.blob.metadata["width"]
      height = @article.cover_image.blob.metadata[:height] || @article.cover_image.blob.metadata["height"]

      return [ width, height ] if width.present? && height.present?

      @article.cover_image.blob.open do |file|
        image = MiniMagick::Image.read(File.binread(file.path))
        return image.dimensions
      end
    rescue MiniMagick::Error, ActiveStorage::FileNotFoundError
      [ nil, nil ]
    end

    def dimensions_from_io(io)
      bytes = io.read
      io.rewind if io.respond_to?(:rewind)

      MiniMagick::Image.read(bytes).dimensions
    rescue MiniMagick::Error
      [ nil, nil ]
    end

    def dimensions_from_attachable(attachable)
      if attachable.is_a?(Hash)
        return dimensions_from_io(attachable[:io]) if attachable[:io].present?

        return [ attachable[:width], attachable[:height] ] if attachable[:width].present? && attachable[:height].present?
      end

      return dimensions_from_io(attachable.tempfile) if attachable.respond_to?(:tempfile)
      return dimensions_from_io(attachable) if attachable.respond_to?(:read)

      [ nil, nil ]
    end
  end
end
