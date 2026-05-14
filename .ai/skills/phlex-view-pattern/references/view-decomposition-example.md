# View Decomposition Example

This reference shows a real-world index view decomposition using the patterns in
`phlex-view-pattern/SKILL.md`. It is drawn from the Studio Articles domain in Papyro.

---

## Before: Monolithic index view (anti-pattern)

A single `Index` class that owns the page layout, the tabs section, every table row
with its dropdowns and badges, and inline pagination — easily 300+ lines and impossible
to test or reuse in isolation.

---

## After: Decomposed structure

### Directory

```text
app/views/studio/articles/
  index.rb                    # Views::Studio::Articles::Index  — page layout only
  index/
    row.rb                    # Views::Studio::Articles::Index::Row
    tabs.rb                   # Views::Studio::Articles::Index::Tabs
    empty_state.rb            # Views::Studio::Articles::Index::EmptyState
    row_actions.rb            # Views::Studio::Articles::Index::RowActions
    row_actions/
      active_actions.rb       # Views::Studio::Articles::Index::RowActions::ActiveActions
      trashed_actions.rb      # Views::Studio::Articles::Index::RowActions::TrashedActions
  edit/
    editor_form_component.rb  # Views::Studio::Articles::Edit::EditorFormComponent
    settings_form_component.rb # Views::Studio::Articles::Edit::SettingsFormComponent
  shared/
    autosave_status.rb        # Views::Studio::Articles::Shared::AutosaveStatus
    slug_input.rb             # Views::Studio::Articles::Shared::SlugInput
app/presenters/
  studio/article_presenter.rb   # display logic extracted from views
```

---

### `app/views/studio/articles/index.rb` — page layout

```ruby
# frozen_string_literal: true

module Views
  module Studio
    module Articles
      class Index < Views::Base
        def initialize(articles:, pagy:, current_tab: "all")
          @articles = articles
          @pagy     = pagy
          @current_tab = current_tab
        end

        def view_template
          # Declare modal placeholder first so Turbo can find it immediately
          turbo_frame_tag("article_publish_modal") { }

          turbo_frame_tag "studio_articles_list" do
            div(class: "bg-background") do
              div(class: "mx-auto max-w-6xl px-4 py-8") do
                render Components::Ui::Card.new do |card|
                  render_header(card)
                  render_body(card)
                end
              end
            end
          end
        end

        private

        def render_header(card)
          card.header(class: "flex flex-row items-center justify-between space-y-0") do
            div do
              card.title(as: :h1) { t("studio.articles.index.title") }
              card.description { t("studio.articles.index.subtitle") }
            end

            render Components::Ui::Button.new(
              as: :a,
              href: studio_articles_path,
              data: { turbo_method: :post, turbo_frame: "_top", testid: "new-article-button" }
            ) { t("studio.articles.index.new_article") }
          end
        end

        def render_body(card)
          card.content do
            # ← sub-component handles all tab logic
            render Tabs.new(current_tab: @current_tab)

            if @articles.empty?
              render_empty_state
            else
              render_table
            end
          end
        end

        def render_empty_state
          div(class: "text-center py-12 px-6") do
            render Components::Ui::Icon.new(:plus, class: "mx-auto h-12 w-12 text-muted-foreground mb-4")
            p(class: "text-base font-medium") { t("studio.articles.index.empty_title") }
            p(class: "text-sm text-muted-foreground mt-1") { t("studio.articles.index.empty_description") }
          end
        end

        def render_table
          div(class: "space-y-4") do
            div(class: "relative w-full overflow-auto min-h-[560px]") do
              render Components::Ui::Table.new do |table|
                table.header { render_table_columns(table) }
                table.body do
                  # ← row sub-component handles all per-row markup
                  @articles.each { |a| render Row.new(article: a) }
                end
              end
            end

            render_pagination if @pagy.pages > 1
          end
        end

        def render_table_columns(table)
          table.row do
            table.head { t("studio.articles.index.columns.article") }
            table.head { t("studio.articles.index.columns.status") }
            table.head { t("studio.articles.index.columns.published") }
            table.head(class: "hidden md:table-cell") { t("studio.articles.index.columns.translations") }
            table.head(class: "text-right") { t("studio.articles.index.columns.actions") }
          end
        end

        def render_pagination
          render Components::Ui::Pagination.new do |pagination|
            pagination.content do
              pagination.item do
                pagination.previous(
                  href: (@pagy.previous ? studio_articles_path(page: @pagy.previous, tab: @current_tab) : nil),
                  data: { turbo_frame: "studio_articles_list" }
                ) { t("design_system.pagination.previous") }
              end
              # ... page links
              pagination.item do
                pagination.next(
                  href: (@pagy.next ? studio_articles_path(page: @pagy.next, tab: @current_tab) : nil),
                  data: { turbo_frame: "studio_articles_list" }
                ) { t("design_system.pagination.next") }
              end
            end
          end
        end
      end
    end
  end
end
```

---

### `app/views/studio/articles/index/row.rb` — extracted row sub-component

```ruby
# frozen_string_literal: true

module Views
  module Studio
    module Articles
      class Index::Row < Views::Base
        def initialize(article:)
          @presenter = ArticlePresenter.new(article)
          @article   = article
        end

        def view_template
          # Renders a single <tr> with all cells, badges, and action dropdown.
          # Focused, testable, composable.
        end
      end
    end
  end
end
```

---

### `app/presenters/article_presenter.rb` — display logic out of views

```ruby
# frozen_string_literal: true

class ArticlePresenter
  def initialize(article)
    @article = article
  end

  # Derived display properties — never inline these in a view
  def display_title
    @article.title.presence ||
      @article.original_title.presence ||
      I18n.t("studio.articles.untitled")
  end

  def status_badge_variant
    @article.published? ? :default : :secondary
  end

  def status_label
    I18n.t("studio.articles.status.#{@article.aasm_state}")
  end

  def published_at_label
    return I18n.t("studio.articles.unpublished") unless @article.published_at

    I18n.l(@article.published_at, format: :short)
  end
end
```

---

## Key Takeaways

1. `Index` owns **page layout only** — it delegates rows, tabs, and empty state.
2. `Row` and `Tabs` are **independently testable** sub-components.
3. `ArticlePresenter` centralises **all display transforms** — title fallback, badge
   variant, date formatting — keeping views free of conditional logic.
4. Pagination uses `Components::Ui::Pagination` — never reimplemented inline.
5. The modal placeholder frame (`"article_publish_modal"`) is declared at the **top** of
   `view_template` before any other content.
6. `turbo_frame: "_top"` is written **explicitly** on the "new article" button because it
   must navigate the full page, not just the `studio_articles_list` frame.

---

## Non-Studio Example 1: Public Author Show Page

This pattern applies outside Studio as well. `Authors::Show` was decomposed into action-owned
parts and a presenter for profile display logic.

### Directory

```text
app/views/authors/
  show.rb                         # Views::Authors::Show (orchestrator)
  show/
    identity_header.rb            # Views::Authors::Show::IdentityHeader
    meta_and_social_links.rb      # Views::Authors::Show::MetaAndSocialLinks
    articles_section.rb           # Views::Authors::Show::ArticlesSection
    pagination.rb                 # Views::Authors::Show::Pagination
app/presenters/authors/
  profile_presenter.rb            # Authors::ProfilePresenter
```

### Parent orchestration pattern

```ruby
class Views::Authors::Show < Views::Base
  def initialize(author:, profile:, articles:, pagy:)
    @presenter = ::Authors::ProfilePresenter.new(author: author, profile: profile)
    @articles = articles
    @pagy = pagy
  end

  def view_template
    div(class: "min-h-screen bg-background text-foreground") do
      render Components::Public::Navbar.new
      main(class: "mx-auto w-full max-w-4xl px-4 py-10 space-y-10") do
        render Show::IdentityHeader.new(presenter: @presenter)
        render Show::ArticlesSection.new(presenter: @presenter, articles: @articles, pagy: @pagy)
      end
    end
  end
end
```

### Why this works

- Public profile display logic (avatar initial, social URLs, ownership checks) lives in presenter.
- `Show` is orchestration-only and action-owned parts are isolated under `show/`.
- Pagination behavior stays explicit and testable in its own component.

---

## Non-Studio Example 2: Design System Catalog Index

Large catalog pages can use staged extraction until parent becomes a thin shell.

### Directory

```text
app/views/design_system/
  index.rb                           # Views::DesignSystem::Index (thin orchestrator)
  index/
    header.rb                        # Views::DesignSystem::Index::Header
    category_nav.rb                  # Views::DesignSystem::Index::CategoryNav
    status_panel.rb                  # Views::DesignSystem::Index::StatusPanel
    foundation_section.rb            # Views::DesignSystem::Index::FoundationSection
    forms_section.rb                 # Views::DesignSystem::Index::FormsSection
    feedback_section.rb              # Views::DesignSystem::Index::FeedbackSection
    overlays_section.rb              # Views::DesignSystem::Index::OverlaysSection
    tables_section.rb                # Views::DesignSystem::Index::TablesSection
    complex_section.rb               # Views::DesignSystem::Index::ComplexSection
    shared/
      section_helpers.rb             # Views::DesignSystem::Index::Shared::SectionHelpers
```

### Parent orchestration pattern

```ruby
class Views::DesignSystem::Index < Views::Base
  def view_template
    div(class: "min-h-screen bg-background text-foreground") do
      div(data: { controller: "design-system" }) do
        render Index::Header.new
        render Index::CategoryNav.new

        main(class: "max-w-7xl mx-auto px-4 py-8") do
          render Index::FoundationSection.new
          render Index::FormsSection.new
          render Index::FeedbackSection.new
          render Index::OverlaysSection.new
          render Index::TablesSection.new
          render Index::ComplexSection.new
          render Index::StatusPanel.new
        end
      end
    end
  end
end
```

### Why this works

- Each catalog section is independently maintainable and easier to review.
- Shared wrappers (`section_container`, `component_card`) live in one small helper module.
- Parent file remains focused on assembly and page-level structure only.
