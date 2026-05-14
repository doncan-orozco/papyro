# Studio Article Presenter Example

This example shows the `Studio::ArticlePresenter` pattern — how to present draft/published articles with translation awareness in the studio editor interface.

## The Presenter

```ruby
# app/presenters/studio/article_presenter.rb
# frozen_string_literal: true

module Studio
  class ArticlePresenter < SimpleDelegator
    # Collection helper for bulk presenter wrapping
    def self.wrap(collection, ui_locale: I18n.locale)
      collection.map { |article| new(article, ui_locale: ui_locale) }
    end

    attr_reader :ui_locale

    def initialize(article, ui_locale: I18n.locale)
      super(article)                           # SimpleDelegator wraps article
      @ui_locale = ui_locale.to_s
    end

    # ─── Locale Selection ───

    def preferred_content_locale
      return ui_locale if has_translation_for_locale?(ui_locale)
      original_locale.to_s
    end

    def content_locale_param(locale = preferred_content_locale)
      locale_str = locale.to_s
      baseline = original_locale.to_s
      return {} if locale_str.blank? || locale_str == baseline

      { content_locale: locale_str }
    end

    # ─── Display Title (Fallback Chain) ───

    def display_title
      # Try UI locale first
      title_in_ui_locale = translation_title_for(preferred_content_locale)
      return title_in_ui_locale if title_in_ui_locale.present?

      # Fall back to original locale
      title_in_original = translation_title_for(original_locale)
      return title_in_original if title_in_original.present?

      # Fall back to mobility raw translation
      mobility_title = Mobility.with_locale(original_locale) { title(fallback: false).to_s.strip }
      return mobility_title if mobility_title.present?

      # Default untitled placeholder
      I18n.t("studio.articles.editor.untitled")
    end

    def untitled_title?(title_to_check)
      title_to_check == I18n.t("studio.articles.editor.untitled")
    end

    # ─── Status & Publication ───

    def status_variant
      return :destructive if trashed?

      case status
      when "draft"
        :secondary
      when "published"
        :default
      when "archived"
        :outline
      else
        :secondary
      end
    end

    def status_label
      if trashed?
        I18n.t("studio.articles.index.statuses.trashed")
      else
        I18n.t("studio.articles.index.statuses.#{status}")
      end
    end

    def published_at_label
      if trashed?
        I18n.t("studio.articles.index.deleted_at", time: I18n.l(deleted_at, format: :short))
      elsif published_at
        I18n.l(published_at, format: :short)
      else
        I18n.t("studio.articles.index.not_published")
      end
    end

    # ─── Translations ───

    def sorted_translations
      baseline = original_locale.to_s
      article_translations.sort_by do |translation|
        # Original locale first, then alphabetical
        [ translation.locale.to_s == baseline ? 0 : 1, translation.locale.to_s ]
      end
    end

    def translation_badge_class(translation)
      # Returns Tailwind classes — but view applies them, not presenter!
      # View decides if this is `link_to` or `span`
      base = "inline-flex h-6 px-2.5 py-0.5 rounded-full text-xs font-semibold transition"
      
      if locale_published?(translation)
        "#{base} bg-primary text-primary-foreground"
      else
        "#{base} bg-muted text-muted-foreground"
      end
    end

    def locale_published?(translation)
      if translation.locale.to_s == original_locale.to_s
        published?
      else
        translation.published?
      end
    end

    # ─── Helpers ───

    private

    def translation_for(locale)
      article_translations.find { |item| item.locale.to_s == locale.to_s }
    end

    def has_translation_for_locale?(locale)
      translation_for(locale).present?
    end

    def translation_title_for(locale)
      translation_for(locale)&.title.to_s.strip
    end
  end
end
```

## Controller Integration

```ruby
# app/controllers/studio/articles_controller.rb
class Studio::ArticlesController < Studio::BaseController
  def index
    skip_policy_scope
    articles_query = Articles::OwnedQuery.call({ user: Current.user, tab: params[:tab] })
    pagy, articles = pagy(articles_query, page: parse_page, limit: 10)

    # Wrap presenters here, not in the view!
    article_presenters = articles.map do |article|
      ::Studio::ArticlePresenter.new(article, ui_locale: I18n.locale)
    end

    render Views::Studio::Articles::Index.new(
      articles: articles,
      article_presenters: article_presenters,
      pagy: pagy,
      current_tab: params[:tab].to_s
    )
  end

  def show
    @article = authorize Article.find_by_uuid!(params[:uuid])
    content_locale = (params[:content_locale] || @article.original_locale).to_sym

    render Views::Studio::Articles::Show.new(
      article: @article,
      presenter: ::Studio::ArticlePresenter.new(@article, ui_locale: content_locale),
      content_locale: content_locale
    )
  end
end
```

## View Integration (Phlex)

### Index View with Presenter

```ruby
# app/views/studio/articles/index.rb
module Views
  module Studio
    module Articles
      class Index < Views::Base
        def initialize(articles:, article_presenters:, pagy:, current_tab:)
          @articles = articles
          @article_presenters = article_presenters
          @pagy = pagy
          @current_tab = current_tab
        end

        def view_template
          div(class: "space-y-4") do
            render Components::Ui::Table.new do |table|
              table.header do
                table.row do
                  table.head { t("studio.articles.index.columns.article") }
                  table.head { t("studio.articles.index.columns.status") }
                  table.head { t("studio.articles.index.columns.published") }
                  table.head { t("studio.articles.index.columns.translations") }
                  table.head { t("studio.articles.index.columns.actions") }
                end
              end

              table.body do
                @articles.each_with_index do |article, idx|
                  presenter = @article_presenters[idx]
                  render Index::Row.new(
                    article: article,
                    presenter: presenter,
                    table: table
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
```

### Row Component Using Presenter

```ruby
# app/views/studio/articles/index/row.rb
module Views
  module Studio
    module Articles
      class Index::Row < Views::Base
        def initialize(article:, presenter:, table:)
          @article = article
          @presenter = presenter  # Always required; passed from parent
          @table = table
        end

        def view_template
          @table.row do
            render_title_cell
            render_status_cell
            render_published_cell
            render_translations_cell
            render_actions_cell
          end
        end

        private

        def render_title_cell
          @table.cell(class: "font-medium") do
            link_to(
              edit_studio_article_path(@article.uuid, **@presenter.content_locale_param),
              data: { turbo_frame: "_top" },
              class: "hover:underline"
            ) do
              title = @presenter.display_title

              if @presenter.untitled_title?(title)
                span(class: "text-muted-foreground italic") { title }
              else
                title
              end
            end
          end
        end

        def render_status_cell
          @table.cell do
            render Components::Ui::Badge.new(
              variant: @presenter.status_variant,
              class: "capitalize"
            ) do
              @presenter.status_label
            end
          end
        end

        def render_published_cell
          @table.cell(class: "text-sm text-muted-foreground") do
            @presenter.published_at_label
          end
        end

        def render_translations_cell
          @table.cell(class: "hidden md:table-cell") do
            translations = @presenter.sorted_translations

            if translations.any?
              div(class: "flex flex-wrap gap-2") do
                translations.each do |translation|
                  link_to(
                    edit_studio_article_path(
                      @article.uuid,
                      content_locale: translation.locale
                    ),
                    data: { turbo_frame: "_top" },
                    class: @presenter.translation_badge_class(translation),
                    title: t(
                      "studio.articles.index.translation_badge_title",
                      locale_name: t("language.name", locale: translation.locale.to_sym)
                    )
                  ) { translation.locale.to_s.upcase }
                end
              end
            else
              span(class: "italic text-muted-foreground") do
                t("studio.articles.index.no_translations")
              end
            end
          end
        end

        def render_actions_cell
          @table.cell(class: "text-right") do
            render Index::RowActions.new(article: @article)
          end
        end
      end
    end
  end
end
```

## Testing the Presenter

```ruby
# test/presenters/studio/article_presenter_test.rb
# frozen_string_literal: true

require "test_helper"

describe Studio::ArticlePresenter do
  let(:article) do
    Article.create!(
      title: "English Title",
      status: "draft",
      original_locale: :en,
      user: create(:user)
    )
  end

  let(:presenter) { Studio::ArticlePresenter.new(article, ui_locale: :en) }

  describe "#display_title" do
    context "when article has translation in UI locale" do
      it "returns title in UI locale" do
        article.update_translations(es: { title: "Título en Español" })
        spanish_presenter = Studio::ArticlePresenter.new(article, ui_locale: :es)
        
        assert_equal "Título en Español", spanish_presenter.display_title
      end
    end

    context "when no translation exists" do
      it "returns original locale title" do
        assert_equal "English Title", presenter.display_title
      end
    end

    context "when article is untitled" do
      it "returns untitled placeholder" do
        article.update!(title: "")
        
        title = presenter.display_title
        assert presenter.untitled_title?(title)
      end
    end
  end

  describe "#status_label" do
    it "returns translated status for draft" do
      article.update!(status: "draft")
      assert_equal I18n.t("studio.articles.index.statuses.draft"), presenter.status_label
    end

    it "returns translated status for published" do
      article.update!(status: "published", published_at: Time.current)
      assert_equal I18n.t("studio.articles.index.statuses.published"), presenter.status_label
    end

    it "returns trashed label when trashed" do
      article.discard!
      assert_equal I18n.t("studio.articles.index.statuses.trashed"), presenter.status_label
    end
  end

  describe "#sorted_translations" do
    it "puts original locale first" do
      article.update_translations(es: { title: "ES" }, fr: { title: "FR" })
      
      sorted = presenter.sorted_translations
      assert_equal :en, sorted.first.locale
      assert [:es, :fr].include?(sorted.last.locale)
    end
  end

  describe ".wrap" do
    it "wraps multiple articles in presenters" do
      articles = [article, Article.create!(title: "Second", user: create(:user))]
      
      presented = Studio::ArticlePresenter.wrap(articles, ui_locale: :es)
      
      assert_equal 2, presented.length
      assert presented.all? { |p| p.is_a?(Studio::ArticlePresenter) }
      assert presented.all? { |p| p.ui_locale == "es" }
    end
  end
end
```

## Key Takeaways

1. **SimpleDelegator** — presenter transparently wraps the article, delegates undefined methods.
2. **Context at init** — `ui_locale` is passed in, determines locale selection strategy.
3. **Collection `.wrap()`** — controller uses it to batch-wrap articles before passing to view.
4. **View receives both** — view gets the article AND presenter (or just presenter if no dual reference needed).
5. **Display logic encapsulated** — all the title fallback, status translation, and locale selection lives in one place.
6. **View focuses on rendering** — view doesn't know about fallback chains; it just calls presenter methods.
