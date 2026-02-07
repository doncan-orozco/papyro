# Papyro AI Agent Guidelines - Structure & Flow

This document explains how to use the guidelines hierarchy to ensure code quality.

## 📚 Checklist Hierarchy

### 0. **entrypoint.md** ← Read FIRST at every session start!
- **Audience**: AI Agent (me)
- **When**: START OF EVERY SESSION (mandatory!)
- **Purpose**: Project guidelines, quick rules, skill index
- **Action**: Read before accepting any task

### 1. **SELF_REVIEW_CHECKLIST.md** ← AI uses this BEFORE responding
- **Audience**: AI Agent (me)
- **When**: Before providing ANY code
- **Purpose**: Quick verification checklist (2 min read)
- **Focus**: Critical issues that must be fixed
- **Action**: Fix issues before responding

### 2. **VERIFICATION_CHECKLIST.md** ← Reference for detailed rules
- **Audience**: Humans + AI (detailed reference)
- **When**: Pre-commit or deep dive
- **Purpose**: Comprehensive guidelines by domain
- **Focus**: Architecture, Frontend, I18n, Turbo Frames
- **Sections**:
  - 🏗️ Architecture & Organization
  - 🎨 Frontend
  - 🌐 Internationalization
  - 🔄 Turbo Frames
  - 🚀 Common Patterns

## 🎯 Workflow

### For AI (me) - SESSION START:
```
🔴 READ entrypoint.md FIRST (mandatory!)
    ↓
Review quick rules + MANDATORY checklist
    ↓
Understand skill index (which skills to load)
    ↓
Ready to accept tasks
```

### For AI (me) - PER TASK:
```
Task Request
    ↓
Load relevant skill files (architecture.md, frontend.md, etc.)
    ↓
Plan implementation
    ↓
Self-review BEFORE coding:
  → Check SELF_REVIEW_CHECKLIST.md
  → Fix any issues found
    ↓
Provide code (guaranteed compliant)
```

### For Humans (you):
```
Commit preparation
    ↓
Review VERIFICATION_CHECKLIST.md (detailed reference)
    ↓
Verify all sections apply to your changes
    ↓
Commit with confidence
```

## 📋 Skill Files Hierarchy

### Master Guidelines
- `ai_agent/entrypoint.md` → Quick rules + links to checklists
- `ai_agent/SELF_REVIEW_CHECKLIST.md` → AI quick-ref (before responding)
- `ai_agent/VERIFICATION_CHECKLIST.md` → Master checklist (single source of truth)

### Backend Skills
- `skills/backend/architecture.md` → Trailblazer patterns, file structure
  - ✓ Links to VERIFICATION_CHECKLIST.md for verification
- `skills/backend/prohibited.md` → What NOT to do
  - ✓ Links to VERIFICATION_CHECKLIST.md for detailed checks
- `skills/backend/turbo.md` → Turbo Frames patterns
  - ✓ Domain-specific checklist for frames
  - ✓ Links to VERIFICATION_CHECKLIST.md

### Frontend Skills
- `skills/frontend/frontend.md` → Phlex, Views, Components, Stimulus
  - ✓ Links to VERIFICATION_CHECKLIST.md for verification
- `skills/frontend/design-system.md` → shadcn/ui + Phlex patterns
- `skills/frontend/i18n.md` → English + Spanish structure
- `skills/frontend/ux.md` → UX/UI guidelines

### Database & Testing
- `skills/database/sqlite.md` → SQLite optimization
- `skills/backend/realtime.md` → Action Cable patterns
- `skills/testing/testing.md` → Minitest patterns
- `skills/testing/linting.md` → RuboCop standards

## ✅ NO Duplication Philosophy

- ❌ DON'T repeat checklist items in every skill file
- ✅ DO link to master VERIFICATION_CHECKLIST.md for detailed rules
- ✅ DO keep skill-specific items only in skill files
- ✅ DO use SELF_REVIEW_CHECKLIST.md as AI quick-ref

## 🚀 Example: Adding a Feature

### 1. AI loads relevant skills:
```
Load: skills/backend/architecture.md
Load: skills/frontend/frontend.md
Load: skills/backend/turbo.md
Reference: SELF_REVIEW_CHECKLIST.md
```

### 2. AI self-reviews before responding:
```
✓ All Views inherit from Views::Base
✓ All Components inherit from Components::Base
✓ I18n files created for both languages
✓ Turbo Frame has matching IDs
... (complete checklist)
```

### 3. AI provides code:
```
"Self-review complete ✓
- Views/Components use proper base classes
- I18n: English + Spanish with domain-based structure
- Turbo Frame properly configured
Implementation ready."
```

### 4. You verify before commit:
```
Review VERIFICATION_CHECKLIST.md
- Frontend section: ✓ All items checked
- I18n section: ✓ All items checked
- Turbo Frames section: ✓ All items checked
Ready to commit
```

## 📍 Quick Links

- **For AI (me)**: Start with [SELF_REVIEW_CHECKLIST.md](SELF_REVIEW_CHECKLIST.md)
- **For Humans (you)**: Start with [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)
- **Architecture questions**: See [skills/backend/architecture.md](skills/backend/architecture.md)
- **Frontend questions**: See [skills/frontend/frontend.md](skills/frontend/frontend.md)
- **Turbo Frames questions**: See [skills/backend/turbo.md](skills/backend/turbo.md)
- **What NOT to do**: See [skills/backend/prohibited.md](skills/backend/prohibited.md)

## 🔄 When to Use What

| Situation | Use This | Then Check |
|-----------|----------|-----------|
| **Session start** | **entrypoint.md** | Quick rules + skill index |
| AI about to respond | SELF_REVIEW_CHECKLIST.md | Before providing code |
| Human pre-commit | VERIFICATION_CHECKLIST.md | All relevant sections |
| Understand patterns | Skill file (architecture.md, etc.) | Links to master checklist |
| Quick reference | Skill file quick rules | SELF_REVIEW_CHECKLIST.md |
| Detailed guidelines | VERIFICATION_CHECKLIST.md | Specific section |

## Summary

- **One master checklist**: VERIFICATION_CHECKLIST.md (source of truth)
- **One AI quick-ref**: SELF_REVIEW_CHECKLIST.md (used before responding)
- **Skill files**: Domain-specific patterns + links to master
- **No duplication**: Clear hierarchy, no conflicting information
- **Clear workflow**: Load skills → self-review → respond → verify → commit
