---
name: web-artifacts
description: Suite of tools for creating elaborate, self-contained HTML/CSS/JavaScript artifacts. Use for interactive components, dashboards, iframes, or standalone pages. Includes templates for common patterns and scripts for bundling.
---

# Web Artifacts (Standalone HTML Components)

## Purpose

Create elaborate, self-contained HTML artifacts that can be:
- Rendered as Turbo frames within Papyro
- Shared as standalone HTML files
- Embedded in emails or documentation
- Used as interactive widgets

**NOT** for standard Phlex components (use [frontend](../frontend/SKILL.md) or [frontend-design](../frontend-design/SKILL.md) for those).

**USE** for:
- Complex interactive dashboards
- Standalone data visualizations
- Email-friendly HTML templates
- Embedded interactive tools
- Shareable widget artifacts

## Stack & Technologies

- **HTML5**: Semantic markup
- **CSS3**: Tailwind CSS or inline styles
- **JavaScript**: Vanilla JS or Stimulus controllers
- **Build Tool**: Parcel (for bundling to single file)
- **Format**: Single HTML file with inlined CSS/JS

## Quick Start

### Step 1: Understanding Artifact Scope

Artifacts are complete, self-contained HTML files. Before building, confirm:
- Is this a complex interactive component?
- Will it be embedded in multiple places?
- Does it need to work standalone?

If no → Use Phlex components in Papyro instead.  
If yes → Use this skill.

### Step 2: Create HTML Artifact

Build a semantic HTML structure with embedded CSS and JavaScript:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Interactive Dashboard</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Geist', system-ui, sans-serif;
      background: #f8fafc;
      padding: 2rem;
    }
    .dashboard {
      max-width: 1200px;
      margin: 0 auto;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 1.5rem;
    }
    .card {
      background: white;
      border-radius: 12px;
      padding: 1.5rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      transition: transform 0.3s, box-shadow 0.3s;
    }
    .card:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 25px rgba(0,0,0,0.1);
    }
  </style>
</head>
<body>
  <div class="dashboard">
    <div class="card">
      <h3>Metric 1</h3>
      <p>Value: <strong id="metric1">0</strong></p>
    </div>
    <div class="card">
      <h3>Metric 2</h3>
      <p>Value: <strong id="metric2">0</strong></p>
    </div>
  </div>

  <script>
    // Demo: Update metrics
    document.getElementById('metric1').textContent = Math.floor(Math.random() * 100);
    document.getElementById('metric2').textContent = Math.floor(Math.random() * 100);
  </script>
</body>
</html>
```

### Step 3: Add Interactivity (if needed)

Use vanilla JavaScript or Stimulus controllers:

```html
<script>
  class Dashboard {
    constructor() {
      this.data = [];
      this.init();
    }

    init() {
      this.loadData();
      this.setupEventListeners();
      this.render();
    }

    loadData() {
      // Load from API, localStorage, or hardcoded
      this.data = [
        { id: 1, label: 'Item 1', value: 42 },
        { id: 2, label: 'Item 2', value: 88 }
      ];
    }

    setupEventListeners() {
      document.querySelectorAll('[data-action]').forEach(el => {
        const [event, method] = el.dataset.action.split(':');
        el.addEventListener(event, () => this[method]());
      });
    }

    render() {
      // Update DOM with data
      console.log('Rendering with data:', this.data);
    }
  }

  new Dashboard();
</script>
```

### Step 4: Testing & Preview

Before sharing, verify:
- [ ] Layout is responsive on mobile/desktop
- [ ] All interactions work correctly
- [ ] No console errors
- [ ] Images/assets are accessible
- [ ] CSS/JS is properly inlined (if bundling to single file)

### Step 5: Bundle to Single HTML (Optional)

For single-file artifacts (useful for sharing/emailing):

```bash
# Option 1: Manual approach
# Ensure all CSS and JS is inlined in HTML

# Option 2: Use bundler
# npm install -g parcel-bundler
# parcel build artifact.html --out-file artifact.bundle.html
```

### Step 6: Integration Options

#### Option A: Render as Turbo Frame
```erb
<!-- In Papyro view -->
<turbo-frame id="artifact">
  <%= render_html_artifact("path/to/artifact.html") %>
</turbo-frame>
```

#### Option B: Embed as Data Attribute
```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    @artifact_html = File.read("app/artifacts/chart.html")
  end
end
```

```erb
<section data-artifact="<%= @artifact_html %>"></section>

<script>
  const section = document.querySelector('[data-artifact]');
  section.innerHTML = section.dataset.artifact;
</script>
```

#### Option C: Serve as Standalone Route
```ruby
# config/routes.rb
get '/artifacts/:name', to: 'artifacts#show'

class ArtifactsController < ApplicationController
  def show
    send_file "app/artifacts/#{params[:name]}.html"
  end
end
```

## Design & Style Guidelines

### Avoid AI Slop

❌ **Don't use**:
- Excessive centered layouts
- Purple gradients on white backgrounds
- Uniform rounded corners everywhere
- Inter font as default
- Cliché color combinations

✅ **Do use**:
- Bold, intentional aesthetic directions
- Distinctive typography choices
- Purposeful spatial composition
- Contextual animations
- Unique color palettes

### Best Practices

1. **Performance**:
   - Minimize CSS and JS
   - Compress images
   - Use CSS Grid/Flexbox instead of heavy JS layouts
   - Avoid unnecessary animations

2. **Accessibility**:
   - Semantic HTML
   - ARIA labels where needed
   - Keyboard navigation
   - Sufficient color contrast

3. **Responsiveness**:
   - Mobile-first CSS
   - Flexible layouts
   - Touch-friendly interactive elements

4. **Maintenance**:
   - Comment complex code
   - Use CSS variables for theming
   - Separate concerns (HTML/CSS/JS)
   - Document any external dependencies

## Common Patterns

### Interactive Form
```html
<form id="interactive-form">
  <input type="text" placeholder="Name" required />
  <select required>
    <option>Choose option...</option>
    <option value="option1">Option 1</option>
  </select>
  <button type="submit">Submit</button>
  <div id="result"></div>
</form>

<script>
  document.getElementById('interactive-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const data = new FormData(e.target);
    document.getElementById('result').innerHTML = `Form submitted: ${JSON.stringify(Object.fromEntries(data))}`;
  });
</script>
```

### Data Visualization
```html
<!-- Use Chart.js or Plotly for charts -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<canvas id="chart"></canvas>

<script>
  const ctx = document.getElementById('chart').getContext('2d');
  const chart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: ['Jan', 'Feb', 'Mar'],
      datasets: [{
        label: 'Revenue',
        data: [12000, 19000, 15000],
        borderColor: '#0369A1',
        backgroundColor: 'rgba(3, 105, 161, 0.1)'
      }]
    }
  });
</script>
```

### Real-time Updates with Stimulus
```html
<div data-controller="live-update">
  <div data-target="live-update.content">Loading...</div>
</div>

<script type="module">
  import { Controller } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@latest"

  export default class extends Controller {
    static targets = ["content"]
    
    connect() {
      this.update();
      setInterval(() => this.update(), 5000);
    }

    update() {
      fetch('/api/data')
        .then(r => r.json())
        .then(data => {
          this.contentTarget.innerHTML = JSON.stringify(data);
        });
    }
  }
</script>
```

## Bundling Scripts (Optional)

For creating production-ready single-file artifacts:

### `scripts/bundle-artifact.sh`
```bash
#!/bin/bash
# Usage: bash scripts/bundle-artifact.sh <input.html> <output.html>

INPUT=${1:-artifact.html}
OUTPUT=${2:-artifact.bundle.html}

# Inline all CSS and JS into single HTML file
# Options: use inliner tools or manual approach

echo "✅ Bundled: $OUTPUT"
```

## Workflow

1. **Requirements**: Confirm artifact scope and requirements
2. **Design**: Plan layout, interactions, and styling
3. **Build HTML**: Create semantic structure
4. **Style**: Add CSS (inline or via `<style>` tags)
5. **Interactivity**: Add JavaScript for interactions
6. **Test**: Verify responsiveness and functionality
7. **Bundle** (optional): Create single HTML file
8. **Integrate**: Use in Papyro views or share standalone
9. **Document**: Add usage instructions if sharing

## Reference

- [MDN Web Docs](https://developer.mozilla.org/en-US/)
- [Tailwind CSS Docs](https://tailwindcss.com/)
- [Chart.js](https://www.chartjs.org/)
- [Plotly.js](https://plotly.com/javascript/)
- [Stimulus JS](https://stimulus.hotwired.dev/)
