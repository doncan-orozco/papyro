# frozen_string_literal: true

module Articles
  module Form
    class Update < Reform::Form
      STATUSES = %w[draft published archived].freeze
      SLUG_FORMAT = /\A[a-z0-9-]+\z/

      feature Reform::Form::Dry
      include Reform::Form::ActiveModel
      include Reform::Form::ActiveModel::FormBuilderMethods

      model :article

      property :id, virtual: true
      property :title
      property :slug
      property :status
      property :body
      property :published_at
      property :excerpt

      validation do
        params do
          optional(:id).maybe(:integer)
          required(:title).filled(:string, max_size?: 255)
          required(:slug).filled(:string, max_size?: 255)
          required(:status).filled(:string)
          optional(:body).maybe(:string, max_size?: 100_000)
          optional(:published_at).maybe(:time)
          optional(:excerpt).maybe(:string, max_size?: 500)
        end

        rule(:slug) do
          next unless value

          if value !~ SLUG_FORMAT
            key.failure(I18n.t("articles.forms.validation.slug_invalid_format"))
          elsif values[:id] && ::Article.where.not(id: values[:id]).exists?(slug: value)
            key.failure(I18n.t("errors.messages.slug_already_exists"))
          end
        end

        rule(:status) do
          key.failure(I18n.t("articles.forms.validation.status_invalid")) if value && !STATUSES.include?(value)
        end

        rule(:published_at) do
          key.failure(I18n.t("errors.messages.published_at_future")) if value && value > Time.current
        end

        rule(:status, :published_at) do
          if values[:status] == "published" && values[:published_at].blank?
            key(:published_at).failure(I18n.t("errors.messages.published_at_required_for_published"))
          end
        end
      end

      def title=(value)
        super(value.to_s.strip)
      end

      def slug=(value)
        super(value.to_s.strip.downcase)
      end
    end
  end
end
