# Self-Review Checklist (AI Agent Use)

**I will review this BEFORE providing any code changes.**

## Critical Issues (Must Fix)
- [ ] All Views inherit from `Views::Base`
- [ ] All Components inherit from `Components::Base`
- [ ] No `Phlex::HTML` used (only base classes)
- [ ] Proper namespaces: `Views::{Domain}`, `Components::{Domain}`
- [ ] ALL user text has i18n keys
- [ ] BOTH English and Spanish translations provided
- [ ] Domain-based locale structure: `config/locales/{en,es}/{file}.yml`
- [ ] No hardcoded strings that users see

## Organization
- [ ] Views in `app/views/{domain}/`
- [ ] Components in `app/components/{domain}/`
- [ ] Controllers are thin
- [ ] Operations/Services contain logic

## Locales
- [ ] English and Spanish files created
- [ ] Scoped keys in views: `t(".title")`
- [ ] Full path keys in components: `t("components.domain.key")`
- [ ] Keys match directory structure

## Turbo Frames (if applicable)
- [ ] Frame has matching ID in request and response
- [ ] Frame represents a domain concept
- [ ] Controller action dedicated to frame
- [ ] Loading strategy intentional (`loading: :lazy` or eager)
- [ ] Route named with helper: `as: :route_name`

## Components
- [ ] Include `**attrs` for Stimulus
- [ ] Data via constructor arguments
- [ ] No implicit variables
- [ ] Pure (no side effects)

## Before responding
1. Read through ALL code I'm about to provide
2. Check each file against this checklist
3. If ANY item fails, FIX IT before responding
4. Add a summary note about what was verified

