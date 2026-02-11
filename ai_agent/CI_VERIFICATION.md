# CI/CD Verification - What Happens When You Push

**Understanding what the CI pipeline checks when code is pushed to GitHub.**

GitHub Actions automatically runs these checks on every pull request and push to `main`:

---

## 🔒 Security Scanning (`scan_ruby` job)

**Runs:** On every PR and push to main

### 1. Brakeman - Rails Security Vulnerabilities
```bash
bin/brakeman --no-pager
```
Checks for common Rails security issues:
- SQL injection vulnerabilities
- Cross-site scripting (XSS) issues
- Unsafe mass assignment
- Hardcoded credentials
- Unsafe redirects/downloads

**If it fails:** You have a security vulnerability. Fix before merging.

**To test locally:**
```bash
bin/brakeman --no-pager
```

### 2. Bundler Audit - Gem Vulnerabilities
```bash
bin/bundler-audit
```
Checks for known vulnerabilities in your gem dependencies.

**If it fails:** A gem has a known security issue. Update or ignore (see `config/bundler-audit.yml`).

**To test locally:**
```bash
bin/bundler-audit
```

---

## 🔓 JavaScript Security (`scan_js` job)

**Runs:** On every PR and push to main

### Importmap Audit - JavaScript Dependency Vulnerabilities
```bash
bin/importmap audit
```
Checks NPM packages for security vulnerabilities.

**If it fails:** A JavaScript package has a vulnerability. Update or replace it.

**To test locally:**
```bash
bin/importmap audit
```

---

## 🧹 Code Quality / Linting (`lint` job)

**Runs:** On every PR and push to main

### RuboCop - Ruby Code Style & Quality
```bash
bin/rubocop -f github
```

Checks for:
- Code style consistency (spacing, indentation, quotes)
- Performance issues
- Rails best practices
- Minitest best practices
- Factory Bot best practices
- Capybara best practices

**If it fails:** Your code doesn't follow the style guide. Fix it.

**To test locally:**
```bash
bin/rubocop                      # Check all files
bin/rubocop --fix-layout         # Auto-fix what can be fixed
bin/rubocop app/controllers/     # Check specific directory
```

**Common failures:**
- Line too long (> 120 chars)
- Incorrect spacing around operators
- Wrong quote style (single vs double)
- Method names not snake_case
- Trailing whitespace
- Indentation errors

See [examples/lint-and-tests.md](examples/lint-and-tests.md) for examples and fixes.

---

## ✅ Tests (`test` job)

**Runs:** On every PR and push to main

### Minitest - All Tests
```bash
rake test
```

Runs:
- Unit tests (Models, Contracts, Operations)
- Integration tests (Controllers, Operations)
- System tests (User workflows with JavaScript)

**If it fails:** A test doesn't pass. Debug and fix.

**To test locally:**
```bash
rake test                        # All tests
rake test TEST=test/models/      # Specific directory
bin/rails test test/models/user_test.rb -v  # Specific file with verbose output
```

**Test expectations:**
- All tests must pass
- New code must have tests
- No skipped tests (unless documented)
- > 90% code coverage (ideally)

See [examples/lint-and-tests.md](examples/lint-and-tests.md) for test patterns.

---

## 🏁 CI Stages in Order

```
Pull Request Created
  ↓
scan_ruby (Brakeman, Bundler-Audit)
scan_js (Importmap Audit)
lint (RuboCop)
test (Minitest)
  ↓
All Pass? → ✅ Ready to merge
All Pass? → ❌ Fix and push again
```

---

## ❌ CI Failed - Quick Troubleshooting

### Security scan failed (Brakeman/Bundler-Audit)
```bash
# See what's wrong
bin/brakeman --no-pager
bin/bundler-audit

# Fix security issue (update gem, change code)
bundle update vulnerable_gem
# OR
# Edit config/bundler-audit.yml to ignore known issues
```

### RuboCop failed
```bash
# Auto-fix what can be fixed
bin/rubocop --fix-layout

# Manually fix remaining issues
bin/rubocop                      # See which rules failed

# Reference for fixes
# → See examples/lint-and-tests.md for common errors
```

### Tests failed
```bash
# Run the failing test
bin/rails test test/path/to_failing_test.rb -v

# Debug the error
# → Follow the error message and stack trace
# → Check fixtures and test setup
# → Verify model/operation behavior

# See test patterns
# → See examples/lint-and-tests.md for testing patterns
```

---

## 🎯 Pre-Push Checklist

Before pushing code, run locally:

```bash
# 1. Security - must pass
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit

# 2. Lint - must pass
bin/rubocop --fix-layout   # Auto-fix
bin/rubocop                # Check remaining

# 3. Tests - must pass
rake test                  # All tests

# 4. Only then push
git push
```

If everything passes locally, it should pass in CI too!

---

## 📊 CI Dashboard

View your checks on GitHub:

1. Go to your **Pull Request**
2. Scroll to **"Checks"** section
3. See status of:
   - ✅ scan_ruby
   - ✅ scan_js
   - ✅ lint
   - ✅ test

Each job shows:
- Status (pass/fail)
- What it's checking
- How long it took
- Log output (click to expand and see full error)

---

## 🔗 CI Configuration

The CI workflows are defined in:
- [.github/workflows/ci.yml](.github/workflows/ci.yml) - Main CI pipeline

Key config files:
- `.rubocop.yml` - RuboCop rules
- `config/bundler-audit.yml` - Bundler audit ignores
- `test/test_helper.rb` - Test configuration

---

## ⚡ Tips for Success

1. **Run checks locally before pushing:**
   ```bash
   bin/rubocop --fix-layout && bin/rubocop && rake test
   ```

2. **Fix auto-fixable issues first:**
   ```bash
   bin/rubocop --fix-layout
   ```

3. **Read error messages carefully** - they include:
   - File name
   - Line number
   - Exact issue
   - How to fix it

4. **Reference the guides:**
   - Lint errors? → [examples/lint-and-tests.md](examples/lint-and-tests.md)
   - Test examples? → [examples/lint-and-tests.md](examples/lint-and-tests.md)
   - Architecture? → [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)

5. **Don't ignore CI failures** - they're there for code quality and security.

---

## 🚀 From CI Back to Your Code

When CI provides feedback:

1. **Read the error message**
2. **Reference the appropriate guide:**
   - Security: Fix the vulnerability
   - Lint: See [examples/lint-and-tests.md](examples/lint-and-tests.md) for fixes
   - Tests: See [examples/lint-and-tests.md](examples/lint-and-tests.md) for patterns
3. **Make changes locally**
4. **Verify locally** (run same check that failed)
5. **Push again**

---

## 📋 What Gets Checked (Complete List)

**Security:**
- SQL injection vulnerabilities
- XSS vulnerabilities
- Unsafe redirects
- Hardcoded secrets
- Vulnerable gem versions
- Vulnerable JavaScript packages

**Code Quality:**
- Style consistency
- Variable naming conventions
- Method complexity
- Performance anti-patterns
- Rails best practices
- Test best practices

**Tests:**
- All tests pass
- New code has tests
- Success and failure cases covered
- No test errors or skips

---

## 🎓 Learning More

- **Security:** See [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md#-security-scanning)
- **Testing:** See skills/testing/testing.md
- **Linting:** See skills/testing/linting.md
- **Architecture:** See VERIFICATION_CHECKLIST.md
