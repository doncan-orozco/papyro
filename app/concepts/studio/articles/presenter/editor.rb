# frozen_string_literal: true

module Studio
  module Articles
    module Presenter
      class Editor < ::Core::Presenter::Base
        attr_reader :article, :content_locale

        def initialize(article, content_locale:)
          @article = article
          @content_locale = content_locale.to_sym
          super(@article)
        end

        def form_url
          if article.persisted?
            helpers.studio_article_path(article.uuid, content_locale: content_locale)
          else
            helpers.studio_articles_path(content_locale: content_locale)
          end
        end

        def form_method
          article.persisted? ? :patch : :post
        end

        def form_data_attributes
          return { turbo: false, testid: "article-editor-form" } unless article.persisted?
          return { turbo: false, testid: "article-editor-form" } if article.trashed?

          {
            controller: "studio--articles--autosave",
            action: "input->studio--articles--autosave#schedule change->studio--articles--autosave#schedule house-md:change->studio--articles--autosave#schedule",
            studio__articles__autosave_saving_value: I18n.t("studio.articles.autosave.saving"),
            testid: "article-editor-form",
            turbo: true
          }
        end

        def title
          Mobility.with_locale(content_locale) do
            is_original_locale? ? article.title : article.title(fallback: false)
          end
        end

        def body
          if is_original_locale?
            article.body.content.to_s
          else
            article.article_translations.find { |t| t.locale == content_locale.to_s }&.content.to_s
          end
        end

        def original_title
          Mobility.with_locale(article.original_locale) { article.title }
        end

        def original_body
          Mobility.with_locale(article.original_locale) { article.body.content.to_s }
        end

        def translation_empty_state?
          return false if is_original_locale?
          title.blank?
        end

        def content_analysis
          @content_analysis ||= ::Articles::Service::ContentAnalysis.new(article)
        end

        private

        def is_original_locale?
          content_locale.to_s == article.original_locale.to_s
        end
      end
    end
  end
end
