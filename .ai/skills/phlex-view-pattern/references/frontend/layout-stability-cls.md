# Layout Stability & CLS Prevention (Frontend)

**Updated**: 2026-05-04

Cumulative Layout Shift (CLS) occurs when page elements move unexpectedly during user interaction. This is especially problematic in data tables with pagination, where users expect pagination controls to stay in the exact same position when navigating pages.

## The Problem

**Scenario**: User clicks "Next" on page 1 of a data table. Page 2 loads with fewer rows or longer content. The pagination controls jump up or down, forcing the user to move their mouse to click "Next" again.

**Impact**: Physical friction, poor UX, looks unpolished.

## Two Root Causes

### 1. Row Height Variation (Text Wrapping)

Long excerpt or description text wraps to multiple lines, making that row taller and shifting the entire table height.

**Solution**: Force all rows to the same height by truncating text to a single line with ellipsis.

```ruby
# BAD — text can wrap to 2+ lines, causing row height variation
table.cell(class: "text-sm text-muted-foreground") do
  span(class: "block line-clamp-2 max-w-[36ch]") { article.excerpt }
end

# GOOD — single line with truncate + fixed max-width
table.cell(class: "max-w-[200px] lg:max-w-[300px]") do
  span(class: "block truncate text-muted-foreground") { article.excerpt }
end
```

**Key Details**:
- `max-w-[200px] lg:max-w-[300px]` constrains the column width (required for truncate to work in table cells)
- `block truncate` forces single-line text with `...` ellipsis
- `text-muted-foreground` maintains visual hierarchy

### 2. Page Height Variation (Short Pages)

When the last page has fewer items (e.g., 4 items on page 3 vs 10 on page 1), the table shrinks and pagination controls jump up.

**Solution**: Lock the table container to a minimum height that accommodates the max number of rows.

```ruby
# BAD — table height shrinks when fewer items are shown
div(class: "space-y-4") do
  render Components::Ui::Table.new do |table|
    # ...
  end
  render_pagination
end

# GOOD — table container locked to min-h for 10 rows (56px each = 560px)
div(class: "space-y-4") do
  div(class: "relative w-full overflow-auto min-h-[560px]") do
    render Components::Ui::Table.new do |table|
      # ...
    end
  end
  render_pagination
end
```

**Calculation**: 
- If pagination limit is 10 items per page
- Each row (with padding) is approximately 56px tall
- Min-height = 10 × 56px = 560px

Adjust based on actual row height in your design.

## Complete Example

```ruby
# app/views/studio/articles/index.rb
def render_articles(card)
  card.content do
    render_tabs

    if @articles.empty?
      # Empty state...
    else
      div(class: "space-y-4") do
        # Wrapper with fixed min-height prevents pagination jump
        div(class: "relative w-full overflow-auto min-h-[560px]") do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("studio.articles.index.columns.article") }
                table.head { t("studio.articles.index.columns.status") }
                table.head { t("studio.articles.index.columns.published") }
                # Excerpt hidden on mobile for responsive design
                table.head(class: "hidden md:table-cell") { t("studio.articles.index.columns.excerpt") }
                table.head(class: "text-right") { t("studio.articles.index.columns.actions") }
              end
            end

            table.body do
              @articles.each do |article|
                render_article_row(table, article)
              end
            end
          end
        end

        render_pagination
      end
    end
  end
end

def render_article_row(table, article)
  table.row do
    table.cell(class: "font-medium") do
      if untitled_title?(article.title)
        span(class: "text-muted-foreground italic") { article.title }
      else
        article.title
      end
    end

    table.cell do
      render Components::Ui::Badge.new(variant: status_variant(article)) do
        article.status
      end
    end

    table.cell(class: "text-sm text-muted-foreground") do
      I18n.l(article.published_at, format: :short)
    end

    # Excerpt: single-line truncate + fixed max-width for responsive design
    table.cell(class: "hidden md:table-cell max-w-[200px] lg:max-w-[300px]") do
      if article.excerpt.present?
        span(class: "block truncate text-muted-foreground") { article.excerpt }
      else
        span(class: "italic") { t("studio.articles.index.no_excerpt") }
      end
    end

    table.cell(class: "text-right") do
      div(class: "flex justify-end") do
        render Components::Ui::DropdownMenu.new do |dropdown|
          # Actions...
        end
      end
    end
  end
end
```

## Tailwind Classes Reference

| Class | Purpose |
|-------|---------|
| `min-h-[560px]` | Locks container height at 560px minimum |
| `max-w-[200px]` | Constrains column width (required for truncate in tables) |
| `block truncate` | Enforces single-line text with ellipsis |
| `text-muted-foreground` | De-emphasizes secondary text |
| `hidden md:table-cell` | Hides column on mobile, shows on desktop |
| `relative w-full overflow-auto` | Allows horizontal scrolling if needed |

## Testing CLS Prevention

### Visual Verification

1. Navigate to your paginated table
2. Populate at least 3 pages (with the final page having fewer items)
3. Rapidly click "Next > Next > Next" without moving your mouse
4. **Result**: Pagination buttons should not jump vertically

### Automated Tests

```ruby
# test/system/articles/pagination_stability_test.rb
test "pagination controls stay in fixed position across pages" do
  # Create articles on multiple pages
  create_list(:article, 25)

  visit articles_path

  page1_pagination_y = page.evaluate_script(
    "document.querySelector('[data-testid=pagination]').getBoundingClientRect().top"
  )

  click_link "2"
  page.wait_for_load_state('networkidle')

  page2_pagination_y = page.evaluate_script(
    "document.querySelector('[data-testid=pagination]').getBoundingClientRect().top"
  )

  assert_equal page1_pagination_y, page2_pagination_y, "Pagination moved vertically!"
end
```

## Best Practices

1. **Always Lock Container Height on Paginated Tables**: Min-height prevents layout shift on short final pages.
2. **Use Truncate for Long Text in Tables**: Never allow table text to wrap; it breaks row height consistency.
3. **Constrain Column Widths**: `max-w-*` on cells with truncated text ensures the Tailwind `truncate` class works.
4. **Test Across Pages**: Verify on the last page where content is likely to be minimal.
5. **Hide Columns on Mobile**: Use `hidden md:table-cell` to avoid cramped layouts and keep rows consistent.
6. **De-Emphasize Secondary Content**: Use `text-muted-foreground` and `italic` for placeholder/"untitled" states instead of changing row height.

## When NOT to Lock Height

- **Dynamic Forms**: If rows add/remove during interaction (e.g., multi-step wizard), locking height creates excess whitespace.
- **Expandable Rows**: If rows can expand to show details, lock the tbody, not the page.
- **Infinite Scroll**: If using infinite scroll instead of pagination, don't lock height.

In these cases, accept minor CLS for better UX. The goal is **intentional** layout decisions, not rigid layouts for their own sake.
