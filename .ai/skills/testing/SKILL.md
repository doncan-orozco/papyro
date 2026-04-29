---
name: testing
description: Testing strategies with Minitest and dry-rb operations. Use when writing tests for operations, contracts, channels, components, views, or system tests. Covers test structure, fixture usage, operation testing patterns, Playwright for system tests, and CI verification.
---

# Testing (Minitest + dry-rb)

## Dependencies
- minitest
- dry-monads
- dry-operation
- dry-validation

## File Structure
```
test/
  concepts/
    game/
      operation/
        move_player_test.rb
      contract/
        move_player_test.rb
    player/
      operation/
        create_test.rb
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

## Suggestions
- Framework: Minitest (Rails-native, fast, minimal)
- Test data: fixtures by default; add FactoryBot if fixtures become unmanageable
- System tests: Playwright (more reliable than Selenium) with Capybara driver

## UI Components (Phlex)
- Render components and assert HTML output.
- Verify variant/size classes and data attributes.
- Keep assertions semantic (avoid brittle class-level expectations when possible).

## Views
- Treat views as integration units: render and assert key sections.
- Avoid snapshot noise; assert only critical content.

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

