# Papyro UI/UX Briefing Guide

Use this template to define the product voice, visual system, and page archetypes before generating views.

## 1) Brand Voice & Tone (Example)

**Adjectives:** calm, editorial, precise

**Mission:** A quiet place to publish thoughtful essays on web development.

**Do / Don’t:**
- **Do:** concise language, confident tone, generous whitespace
- **Don’t:** salesy CTAs, noisy gradients, cluttered layouts

## 2) Visual System (Example)

**Typography**
- Display: "IBM Plex Serif"
- Body: "Inter"
- Scale: 48 / 32 / 24 / 18 / 16 / 14

**Spacing**
- Base: 4px
- Rhythm: 4/8/12/16/24/32/48/64

**Colors**
- Primary: slate-900
- Accent: emerald-600
- Background: neutral-50
- Surface: white
- Border: neutral-200

**Radius + Shadow**
- Radius: md (6px)
- Shadow: subtle (shadow-sm)

**Buttons + Links**
- Primary: solid dark
- Secondary: outline
- Links: underline on hover

## 3) Page Archetypes (Example)

**Landing (About/Portfolio)**
- Hero with title, short bio, primary CTA
- Featured articles grid
- Skills/stack list
- Contact/footer

**Article Index**
- Search/filter bar
- Cards with title, excerpt, tags, date

**Article Detail**
- Title + meta
- Reading time + tags
- Long‑form content

**Editor**
- Title + subtitle inputs
- Markdown/preview toggle
- Save/Publish actions

## 4) Reference Links (Example)

- https://writebook.app
- https://medium.com
- https://matthewsiu.com

## 5) Content Samples (Example)

**Hero Title:** Building calm software

**Hero Subtitle:** Essays about design systems, Rails architecture, and product craft.

**CTA:** Read the latest essay

**Sample Excerpt:**
“Design is a series of deliberate constraints. In this essay, we explore how a simple typographic grid can shape both interface and thought.”

## 6) Output Expectations

This section is a template for product expectations. Required rules live in the checklist:
- [Frontend rules](../ai_agent/VERIFICATION_CHECKLIST.md#-frontend)
- [I18n rules](../ai_agent/VERIFICATION_CHECKLIST.md#-internationalization-i18n)

When generating views (example expectations):
- Use Phlex + shadcn-style components
- Keep layouts clean, editorial, and readable
- Prefer content-first structure over decorative UI
- Ensure i18n keys are used for all copy
