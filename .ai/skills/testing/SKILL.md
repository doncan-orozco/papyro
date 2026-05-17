---
name: testing
description: Testing strategies with Minitest and dry-rb operations. Use when writing tests for operations, contracts, channels, components, views, or system tests. Covers test structure, fixture usage, operation testing patterns, Playwright for system tests, and CI verification.
---

# Testing (Minitest + dry-rb)

## Dependencies
- minitest
- dry-monads
- dry-validation

## File Structure
```
test/
  operations/
    game/
      operation/
        move_player_test.rb
    player/
      operation/
        create_test.rb
  contracts/
    game/
      contract/
        move_player_test.rb
  channels/
    game_channel_test.rb
  fixtures/
```

## Coverage Examples
- Operations in isolation (happy + failure paths)
- Contracts for validation
- Channels for WebSocket authorization
- Broadcast assertions for realtime features
- Fixtures for test data
- Small, explicit tests

## Concept Coverage Policy (Required)

For concept-layer coverage, enforce a mirrored test structure:

1. Every file under `app/concepts/**/operation/*.rb` must have a corresponding test under `test/concepts/**/operation/*_test.rb`.
2. Every file under `app/concepts/**/query/*.rb` must have a corresponding test under `test/concepts/**/query/*_test.rb`.
3. Every file under `app/concepts/**/presenter/*.rb` must have a corresponding test under `test/concepts/**/presenter/*_test.rb`.
4. Every file under `app/concepts/**/service/*.rb` must have a corresponding test under `test/concepts/**/service/*_test.rb`.
5. Core abstractions under `app/concepts/core/` must have lightweight contract tests to lock base behavior.

Minimum expectation per concept test file:

1. At least one success-path assertion.
2. At least one failure/edge-path assertion (where applicable).
3. Result payload shape checks for operation/query contracts.

## Suggestions
- Framework: Minitest (Rails-native, fast, minimal)
- Test data: fixtures by default; add FactoryBot if fixtures become unmanageable
- System tests: Playwright (more reliable than Selenium) with Capybara driver

## Host-Coupled Engine Harness (PapyroStudio)

Use this pattern when engine code depends on host models, DB schema, and authentication:

1. Engine test helper boots the host environment (for this workspace, via sibling host app path).
2. Engine tests run from host app root (not inside engine directory) to ensure one source of truth for boot/runtime.
3. Keep fixtures sourced from host app fixture paths in the engine test helper.

### Coverage Ownership Split

1. Engine test suite should own studio request/policy/presenter depth tests.
2. Host test suite should keep a small smoke boundary for mount/subdomain/session integration.
3. Avoid duplicate suite ownership across host and engine; remove migrated host duplicates after parity is confirmed.

### Commands

From host app root:

1. `bin/rails test`
2. `bin/rails test ../papyro_studio/test`
3. `bin/rails test:with_studio`

See [references/tests.md](references/tests.md) for concrete examples.

## UI Components (Phlex)
- Render components and assert HTML output.
- Verify variant/size classes and data attributes.
- Keep assertions semantic (avoid brittle class-level expectations when possible).

## Views
- Treat views as integration units: render and assert key sections.
- Avoid snapshot noise; assert only critical content.

## Flash & Toast Notifications

### Integration Tests (Controller Flash)
Flash messages render as toasts in the layout. Test by asserting the toast container and message text:

```ruby
# test/controllers/articles_controller_test.rb
test "create action redirects with success flash" do
  post articles_path, params: { article: valid_params }
  
  assert_redirected_to article_path(@article)
  follow_redirect!
  
  # Toast renders as div[role=status] with the flash message
  assert_select "div[role=status]", /#{I18n.t("articles.operations.create.success")}/
end

test "create action with invalid data shows error flash" do
  post articles_path, params: { article: invalid_params }
  
  assert_response :unprocessable_entity
  
  # Error toast is destructive variant with alert message
  assert_select "div[role=status][class*='destructive']", /Error/
end
```

### Component Unit Tests
Test the Toast and Flash components in isolation:

```ruby
# test/components/shared/flash_test.rb
test "flash renders notice as success toast" do
  flash = { notice: "Article saved" }
  
  render_inline Components::Shared::Flash.new(flash: flash)
  
  assert_text "Success"
  assert_text "Article saved"
  assert_selector "[data-controller='toast']"
  assert_selector "[data-state='open']"
end

test "flash renders alert as destructive toast" do
  flash = { alert: "Error occurred" }
  
  render_inline Components::Shared::Flash.new(flash: flash)
  
  assert_text "Error"
  assert_text "Error occurred"
  assert_selector "[class*='destructive']"
end

test "toast auto-dismisses after duration" do
  render_inline Components::Ui::Toast.new do |toast|
    toast.description { "Test message" }
  end
  
  assert_selector "[data-toast-duration-value='4000']"
end
```

### System Tests (Full User Flow)
Verify toast visibility and behavior in rendered pages:

```ruby
# test/system/articles/create_article_flow_test.rb
test "user sees success toast after creating article" do
  visit new_article_path
  fill_in "Title", with: "New Article"
  fill_in "Excerpt", with: "Test excerpt"
  click_button "Create"
  
  assert_current_path article_path(@article)
  
  # Toast is visible and accessible
  assert_selector "[role='status'][aria-live='polite']", text: "Success"
end

test "toast closes when user clicks close button" do
  visit new_article_path
  fill_in "Title", with: "Test"
  click_button "Create"
  
  assert_selector "[role='status']", text: "Success"
  
  click_button I18n.t("app.toasts.close")
  
  assert_no_selector "[role='status']"
end
```

**Key Assertions for Toast Testing**:
- Use `div[role=status]` selector (not `p#notice`)
- Assert `aria-live="polite"` for accessibility
- Verify `[data-controller='toast']` for Stimulus wiring
- Check `[data-state='open']` for visibility state
- For destructive (error) toasts, assert `[class*='destructive']` variant

## SEO Integration Coverage
- For every public URL that should be indexable, add an integration test for head metadata.
- Assert the canonical URL, locale alternates, and `x-default` hreflang tag.
- Assert the base social tags as well: `title`, `meta[name='description']`, `og:title`, `og:description`, `og:locale`, and `og:locale:alternate`.
- Cover at least the home page, public index pages, public show pages, and public profile pages when they exist.
- Treat missing SEO assertions on a new public route as missing required coverage, not optional follow-up work.

## System Testing with Playwright

### Setup & Configuration
```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { 
    args: %w[headless] 
  }
  # Or use Playwright:
  # driven_by :playwright, using: :chromium, screen_size: [1400, 1400]
end
```

### Key Patterns

#### Element Discovery
Before interacting with elements, discover them using Playwright:

```ruby
# Take screenshot to inspect current state
page.save_screenshot("screenshot.png")

# Find elements using various selectors
page.find("button", text: "Submit")
page.find("[data-test-id='save-btn']")
page.find(".primary-action")

# Wait for elements to appear
page.find("h1", text: "Dashboard", visible: :all)
page.wait_for_selector(".spinner", timeout: 5000)

# Check element state
button = page.find("button", text: "Submit")
assert button.visible?
assert_not button.disabled?
```

#### Reconnaissance-Then-Action Pattern

For dynamic webapps, inspect first, then interact:

```ruby
# 1. Navigate and wait for JS to execute
page.visit articles_path
page.wait_for_load_state('networkidle')

# 2. Take screenshot or inspect DOM
page.save_screenshot("state.png")
content = page.content
buttons = page.locator("button").all

# 3. Identify selectors from rendered state
form = page.locator("form[data-controller='article-form']")
submit_btn = form.locator("button", text: "Submit")

# 4. Execute actions with discovered selectors
title_input = form.locator("input[name='article[title]']")
title_input.fill("My Article")
submit_btn.click

# 5. Wait for results
page.wait_for_selector(".alert-success", timeout: 5000)
assert page.find(".article-title", text: "My Article")
```

### Common Test Scenarios

#### Testing Forms with Validation
```ruby
def test_article_creation_with_validation
  visit articles_path
  click_link "New Article"
  
  # Verify form elements exist
  assert_text "Create Article"
  assert_selector "input[name='article[title]']"
  
  # Submit empty form
  click_button "Create"
  assert_text "Title can't be blank"
  
  # Fill and submit
  fill_in "article[title]", with: "Great Article"
  fill_in "article[content]", with: "Amazing content..."
  click_button "Create"
  
  # Verify redirect and content
  assert_current_path article_path(Article.last)
  assert_text "Article created successfully"
end
```

#### Testing Turbo Interactions
```ruby
def test_turbo_frame_update
  visit articles_path("sort=newest")
  
  # Wait for Turbo frame to load
  assert_selector "turbo-frame#articles-list"
  
  # Trigger Turbo action
  click_link "Sort by oldest"
  
  # Wait for frame update (Turbo handles this)
  assert_text "Article A" # Should appear in reversed order
  
  # Verify URL didn't change (frame update only)
  assert_current_path articles_path("sort=oldest")
end
```

#### Testing Real-time Features
```ruby
def test_article_broadcast_update
  # Open first browser window
  visit article_path(@article)
  
  # Open second browser window
  using_session("editor") do
    visit article_edit_path(@article)
    fill_in "article[title]", with: "Updated Title"
    click_button "Save"
  end
  
  # First browser receives broadcast
  assert_text "Updated Title"
end
```

#### Testing Stimulus Controllers
```ruby
def test_stimulus_form_validation
  visit articles_path("new")
  
  # Stimulus controller provides real-time validation
  fill_in "article[title]", with: "" # Empty
  assert_selector ".field-error" # Stimulus shows error
  
  fill_in "article[title]", with: "Valid Title"
  assert_no_selector ".field-error" # Stimulus clears error
end
```

### Best Practices

✅ **Do**:
- Wait for `networkidle` before interacting with dynamic elements
- Use semantic selectors: `text=`, `role=`, `data-test-id`
- Take screenshots for debugging
- Use `visible?` to check element visibility
- Test happy path + error cases
- Keep system tests focused on critical user flows

❌ **Don't**:
- Make assertions before waiting for elements to appear
- Use brittle nth-child or complex CSS selectors
- Test implementation details (test behavior, not code)
- Interact with elements before they're fully rendered
- Mix unit tests with integration tests

### Debugging & Inspection

```ruby
# Capture console logs during test
page.on_console_message { |msg| puts "JS: #{msg.text}" }

# Inspect page content
puts page.content
puts page.locator(".article-title").text_content

# Check for errors
network_errors = page.evaluate("window.__errors || []")
puts "Network errors: #{network_errors}"

# Inspect accessibility tree
accessibility = page.evaluate("document.body.outerHTML")
puts accessibility
```

### Performance Considerations

```ruby
# For tests that interact with heavy JS frameworks:
page.set_default_timeout(10000)

# Optimize by reducing screenshot captures
# Take selective screenshots only when needed for debugging

# Use headless mode in CI for speed
ENV['HEADLESS'] = true if ENV['CI']
```

## Playwright Automation (Advanced)

For complex end-to-end testing workflows, use Playwright directly:

```python
# test/support/playwright_automation.py (optional)
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    
    # Navigate and wait
    page.goto("http://localhost:3000/articles")
    page.wait_for_load_state('networkidle')
    
    # Interact
    page.locator("button", text="Create").click()
    page.wait_for_url("**/articles/new")
    
    # Assert
    assert page.locator("h1").text_content() == "Create Article"
    
    browser.close()
```

## Test Organization

```
test/
  application_system_test_case.rb
  test_helper.rb
  
  concepts/
    articles/
      operation/
        create_test.rb
      contract/
        create_contract_test.rb
    
  controllers/
    articles_controller_test.rb
  
  components/
    article_card_test.rb
  
  system/
    articles/
      create_article_test.rb
      edit_article_test.rb
      sort_articles_test.rb
    
  fixtures/
    articles.yml
    users.yml
```

## Coverage Checklist

- [ ] Operations: happy path + all failure cases
- [ ] Contracts: all validation rules
- [ ] Components: rendering + variants
- [ ] System tests: critical user flows
- [ ] Real-time: broadcasts + WebSocket updates
- [ ] Error handling: validation errors, network errors
- [ ] Accessibility: keyboard navigation, ARIA labels

## CI/CD Verification Pipeline

### What CI Checks On Every Push

When you push code to GitHub, the CI pipeline automatically runs:

#### 1. Security Scanning
```bash
bin/brakeman --no-pager          # Rails security vulnerabilities
bin/bundler-audit                 # Gem dependency vulnerabilities
bin/importmap audit               # JavaScript package vulnerabilities
```

**What it checks for:**
- SQL injection vulnerabilities
- Cross-site scripting (XSS) issues
- Unsafe mass assignment
- Hardcoded credentials
- Unsafe redirects/downloads
- Known vulnerabilities in gems and packages

#### 2. Code Quality (RuboCop)
```bash
bin/rubocop -f github
```

**What it checks:**
- Code style consistency
- Performance issues
- Rails best practices
- Minitest best practices
- Factory Bot patterns
- Capybara patterns

#### 3. Tests (Minitest)
```bash
rake test
```

**Runs all tests:**
- Unit tests (Models, Contracts, Operations)
- Integration tests (Controllers, Operations)
- System tests (User workflows with Playwright)

**Requirements:**
- All tests must pass
- New code must have tests
- No skipped tests (unless documented)

### Pre-Push Local Verification

Before pushing, run these checks locally:

```bash
# 1. Security checks (must pass)
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit

# 2. Code quality (must pass)
bin/rubocop --fix-layout   # Auto-fix what can be fixed
bin/rubocop                # Check remaining issues

# 3. Tests (must pass)
rake test                  # All tests

# 4. Only then push
git push
```

### Troubleshooting CI Failures

**Security failures:**
```bash
# Review issue
bin/brakeman --no-pager
# Fix vulnerability or update gems
bundle update vulnerable_gem
```

**RuboCop failures:**
```bash
# Auto-fix what can be fixed
bin/rubocop --fix-layout

# See remaining issues
bin/rubocop

# Check for common patterns
# → See skills/linting/references/lint-and-tests.md
```

**Test failures:**
```bash
# Run specific failing test
bin/rails test test/path/to_failing_test.rb -v

# Debug: check error message and stack trace
# → Verify fixtures and test setup
# → Check model/operation behavior
# → Reference test patterns in this skill
```

### CI Pipeline Order

```
Pull Request Created
  ↓
1. Security (Brakeman, Bundler-Audit, Importmap)
2. Code Quality (RuboCop)
3. Tests (Minitest)
  ↓
All Pass? → ✅ Ready to merge
Any Fail? → ❌ Fix locally, push again
```

### Checking CI Status

On GitHub:
1. Go to your **Pull Request**
2. Scroll to **Checks** section
3. View status of each job
4. Click to expand logs for details

