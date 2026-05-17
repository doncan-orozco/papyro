---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when building Phlex components, views, and pages with exceptional aesthetic polish. Covers design thinking, typography, color theming, animations, and avoiding generic AI aesthetics.
---

# Frontend Design (Rails/Phlex/Tailwind)

## Purpose

Create distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. This skill guides the development of visually striking components and pages with intentional design decisions, integrated with Papyro's tech stack.

## Prerequisite UX Inputs

Before applying this skill, align with the UX knowledge base:

- Fill the brief in [../ux/references/design-brief-template.md](../ux/references/design-brief-template.md)
- Validate context in [../ux/references/ux-investigation-synthesis.md](../ux/references/ux-investigation-synthesis.md)
- Verify outcomes with [../ux/references/ux-review-checklist.md](../ux/references/ux-review-checklist.md)

This skill defines visual execution quality. UX intent must be explicit first.

## Design Thinking

Before coding, understand the context and commit to a **BOLD** aesthetic direction:

### Strategic Questions
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme conviction:
  - Brutally minimal
  - Maximalist chaos
  - Retro-futuristic
  - Organic/natural
  - Luxury/refined
  - Playful/toy-like
  - Editorial/magazine
  - Brutalist/raw
  - Art deco/geometric
  - Soft/pastel
  - Industrial/utilitarian

- **Constraints**: Technical requirements (Rails/Phlex, Tailwind CSS, performance, accessibility)
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work—the key is intentionality, not intensity.

## Implementation with Phlex & Tailwind CSS

Then implement working code (Phlex components or views) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

### Component Structure
```ruby
module Components::Ui
  class Button < Components::Base
    attr_reader :label, :variant, :size

    def initialize(label:, variant: :primary, size: :md, **attrs)
      @label = label
      @variant = variant
      @size = size
      super(**attrs)
    end

    def view_template
      button(**html_attrs) { label }
    end

    private

    def html_attrs
      {
        class: class_names(
          base_classes,
          variant_classes[@variant],
          size_classes[@size],
          @class
        ),
        **@attrs
      }
    end

    def base_classes
      "inline-flex items-center justify-center font-semibold transition-all"
    end

    def variant_classes
      {
        primary: "bg-amber-600 text-white hover:bg-amber-700 shadow-lg",
        secondary: "bg-slate-200 text-slate-900 hover:bg-slate-300",
        ghost: "text-slate-700 hover:bg-slate-100"
      }
    end

    def size_classes
      {
        sm: "px-3 py-1.5 text-sm rounded-md",
        md: "px-4 py-2 text-base rounded-lg",
        lg: "px-6 py-3 text-lg rounded-xl"
      }
    end
  end
end
```

## Frontend Aesthetics Guidelines

### Typography
- **Choose distinctive fonts**, not generic defaults:
  - ❌ Avoid: Arial, Inter, Roboto, system fonts
  - ✅ Use: Unique display fonts + refined body fonts
- Pair a distinctive display font with an elegant body font
- Consider web-safe options via Google Fonts or custom host fonts
- Set appropriate `font-weight`, `letter-spacing`, and `line-height` for visual hierarchy

Example Tailwind configuration:
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    fontFamily: {
      display: ['Playfair Display', 'serif'],  // distinctive display
      body: ['Geist', 'sans-serif'],           // refined body
    },
  }
}
```

### Color & Theme
- **Commit to a cohesive aesthetic**
- Use CSS variables for consistency (via Tailwind config)
- Dominant colors with sharp accents outperform timid, evenly-distributed palettes
- Consider dark/light mode variants
- Use meaningful color semantics (not just pretty colors)

Example Tailwind theme:
```javascript
// tailwind.config.js
theme: {
  colors: {
    primary: '#B4860B',    // Golden dominant
    accent: '#D63384',     // Rose accent
    slate: {...},          // Neutrals
  },
  // Use in components
}
```

### Motion & Interactions
- Use animations for effects and micro-interactions
- Prioritize CSS-only solutions for HTML/Phlex
- Focus on high-impact moments: one well-orchestrated page load with staggered reveals
- Create scroll-triggered animations using libraries like AOS or Stimulus
- Surprise with hover states and unexpected transitions

Example with Tailwind:
```ruby
class Components::Card < Components::Base
  def view_template
    div(class: "group p-6 rounded-xl hover:shadow-2xl transition-all duration-300") {
      h2(class: "text-2xl font-bold group-hover:translate-y-1 transition-transform") {
        "Card Title"
      }
      p(class: "opacity-70 group-hover:opacity-100 transition-opacity") {
        "Details appear on hover"
      }
    }
  end
end
```

### Polished Tables & Data Grids

Data tables and lists demand special attention to detail. Key polish indicators:

**1. Row Height Consistency**
- Lock all rows to identical height with truncated text (no wrapping)
- Use `truncate` class + `max-w-*` constraints to prevent text overflow
- De-emphasize secondary content (untitled items, placeholders) with `text-muted-foreground italic`

```ruby
# Good: all rows identical height, text single-line with ellipsis
table.cell(class: "max-w-[200px] lg:max-w-[300px]") do
  span(class: "block truncate text-muted-foreground") { item.excerpt }
end

# Bad: text wraps, making row heights variable
table.cell(class: "text-sm") do
  span(class: "line-clamp-2") { item.excerpt }
end
```

**2. Layout Stability (CLS Prevention)**
- Lock table container to `min-h-[560px]` (or appropriate height) for max pagination items
- Prevents pagination controls from jumping up/down when pages have fewer items
- Load [../frontend/references/layout-stability-cls.md](../frontend/references/layout-stability-cls.md) for detailed guidance

```ruby
# Good: fixed min-height prevents pagination jump
div(class: "relative w-full overflow-auto min-h-[560px]") do
  render Components::Ui::Table.new { |table| ... }
end
```

**3. Visual Hierarchy in Tables**
- Primary column (title/name): `font-medium`
- Secondary columns (status, date): `text-sm text-muted-foreground`
- Actions column: right-aligned with `flex justify-end`
- Responsive behavior: hide tertiary columns on mobile with `hidden md:table-cell`

```ruby
table.row do
  table.cell(class: "font-medium") { item.title }  # Primary
  table.cell(class: "text-sm text-muted-foreground") { item.status }  # Secondary
  table.cell(class: "hidden md:table-cell text-muted-foreground") { item.excerpt }  # Hidden mobile
  table.cell(class: "text-right") { render Actions.new(item: item) }  # Right-aligned
end
```

### Spatial Composition
- Embrace unexpected asymmetrical layouts
- Use negative space strategically
- Create visual rhythm with intentional spacing
- Break grid conventions when it serves the design
- Layering and overlap for depth
- Consider gesture-driven interfaces for interactive elements

### Backgrounds & Visual Details
- Create atmosphere and depth, not just solid colors
- Add contextual effects and textures
- Apply creative forms:
  - Gradient accents (subtle, purposeful)
  - Noise/grain overlays for texture
  - Geometric patterns matching the aesthetic
  - Layered transparencies for depth
  - Dramatic shadows for hierarchy
  - Decorative borders and dividers
  - Custom cursors for brand consistency

Example with Tailwind + pseudo-elements:
```ruby
div(class: "relative overflow-hidden rounded-2xl") {
  # Background atmospheric element
  div(class: "absolute inset-0 bg-gradient-to-br from-blue-500/20 via-purple-500/20 to-transparent blur-3xl")
  
  # Content with relative positioning
  div(class: "relative p-8") { content }
}
```

## Anti-Patterns: What NOT to Do

❌ **AVOID**:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Cliched color schemes (particularly purple gradients on white)
- Predictable layouts and cookie-cutter component patterns
- Overuse of rounded corners on everything
- Centered layouts for every section
- Generic AI-generated aesthetics
- Auto-focus or focus restoration on initial page load that scrolls the viewport unexpectedly

✅ **DO**:
- Vary between light and dark themes
- Use different fonts across different designs
- Make unexpected, contextual design choices
- Ensure designs are intentionally crafted for their purpose
- Show what can be created with bold, distinctive vision

## Workflow

1. **Understand requirements** - Ask clarifying questions about purpose, audience, and context
2. **Choose aesthetic direction** - Commit to a bold, intentional direction
3. **Design the layout** - Sketch spatial composition and visual hierarchy
4. **Implement components** - Build reusable Phlex components with Tailwind CSS
5. **Apply typography & color** - Use distinctive fonts and cohesive color palette
6. **Add motion & effects** - Implement animations and micro-interactions
7. **Refine details** - Polish spacing, shadows, and visual accents
8. **Test responsiveness** - Ensure design works across devices
9. **Iterate** - Gather feedback and refine

## UX/UI Briefing Template

Before starting design implementation, define the product voice and visual system:

### 1. Brand Voice & Tone

Define the personality using 3 adjectives and the core mission:

**Example:**
- **Adjectives**: calm, editorial, precise
- **Mission**: A quiet place to publish thoughtful essays on web development
- **Do**: concise language, confident tone, generous whitespace
- **Don't**: salesy CTAs, noisy gradients, cluttered layouts

### 2. Visual System

**Typography**
- Display font: distinctive, memorable
- Body font: readable, refined
- Type scale: hierarchy from 12px to 48px

**Spacing**
- Base unit: 4px or 8px
- Rhythm: scale (4/8/12/16/24/32/48/64)

**Colors**
- Primary: dominant color for key actions
- Accent: secondary highlight color
- Background: page background
- Surface: card/container background
- Border: divider and edge colors

**Radius & Shadow**
- Border radius: 0px (sharp), 4-6px (modern), 12px+ (rounded)
- Shadow: subtle, medium, dramatic for different elevations

**Components**
- Button styles: primary (solid), secondary (outline), ghost (minimal)
- Link styles: underline on hover, color on focus
- Form states: normal, focus, error, disabled

### 3. Page Archetypes

Define key page types and their structure:

**Example - Landing Page:**
- Hero section with title, subtitle, CTA
- Featured content grid
- About/skills section
- Contact/footer

**Example - List/Index Page:**
- Search/filter bar
- Card-based grid layout
- Pagination or infinite scroll

**Example - Detail Page:**
- Title + metadata
- Long-form content area
- Related items or comments

**Example - Editor/Form:**
- Input fields organized by section
- Preview toggle
- Save/publish actions

### 4. Content Voice

Provide sample copy demonstrating the brand voice:

- **Headlines**: Bold, declarative, action-oriented
- **Body copy**: Clear, concise, jargon-free
- **CTAs**: Direct, specific, personality-filled
- **Micro-copy**: Helpful error messages, confirmations, hints

**Examples:**
- Hero: "Building calm software"
- Description: "Essays about design, architecture, and craft"
- CTA: "Read the latest essay"
- Error: "Title should be 5-100 characters" (not "Invalid input")

### 5. Reference Inspiration

List 2-3 reference sites that match the desired aesthetic:
- Include URL
- Note what specifically is inspiring (typography, layout, color, motion, etc.)

### 6. Accessibility & Inclusivity

Define accessibility requirements:
- Color contrast: WCAG AA (1:4.5 for text) minimum
- Responsive: works on mobile, tablet, desktop
- Keyboard navigation: all interactive elements accessible
- Screen reader: semantic HTML, ARIA labels where needed
- Language support: English + Spanish (Papyro requirement)

## Integration with Papyro

- **Components**: Store in `app/components/` organized by domain
- **Views**: Store in `app/views/` for page-level templates
- **Styling**: Use Tailwind CSS utilities + custom CSS variables
- **Responsive**: Mobile-first approach with Tailwind breakpoints
- **Accessibility**: WCAG 2.1 AA compliance with semantic HTML
- **Performance**: Optimize images, minimize CSS-in-JS overhead

## References

- **[references/blank-canvas-editor.md](references/blank-canvas-editor.md)**
  Use when implementing distraction-free writing interfaces (Medium/Notion/Ghost-style). Covers: sticky borderless action bar, max-w-3xl canvas, unstyled title/body fields, House markdown editor integration, and the double-header anti-pattern.

- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Google Fonts](https://fonts.google.com/)
- [Web Safe Colors & Palettes](https://colorhunt.co/)
- [Phlex Components](https://www.phlex.fun/)

## Companion Skills

- **[../phlex-view-pattern/SKILL.md](../phlex-view-pattern/SKILL.md)** — **PRIMARY view structure source**: Golden archetype for all Phlex views and components. Load this first for any work in `app/views/` or `app/components/`. This frontend-design skill adds the visual polish layer on top of the structure governed by phlex-view-pattern.
- **[../frontend/SKILL.md](../frontend/SKILL.md)** for Stimulus and Hotwire integration
- **[../design-system/SKILL.md](../design-system/SKILL.md)** for shadcn/Phlex UI primitive patterns
