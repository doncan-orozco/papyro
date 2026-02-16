---
name: theme-factory
description: Toolkit for managing and applying UI themes to Papyro applications. Provides 10 pre-configured themes with cohesive color palettes and font pairings that can be applied to any Phlex component or view. Also supports creating custom themes on-the-fly.
---

# Theme Factory (Tailwind CSS Theming)

## Purpose

Apply consistent, professional styling across Papyro applications using pre-configured themes. Each theme includes:
- A cohesive color palette with hex codes
- Complementary font pairings for headers and body text
- A distinct visual identity suitable for different contexts and audiences
- Instructions for integration with Tailwind CSS

## Usage Instructions

### Step 1: Show Theme Options
Display available themes for user selection (see Themes Available section).

### Step 2: Ask for Theme Choice
Ask which theme to apply to their Papyro application/component.

### Step 3: Wait for Confirmation
Get explicit confirmation about the chosen theme before proceeding.

### Step 4: Apply the Theme
Once selected, apply the theme by:
1. Reading the corresponding theme file from `themes/` directory
2. Updating `tailwind.config.js` with the theme's colors and fonts
3. Applying theme CSS variables across components
4. Ensuring proper contrast and readability
5. Maintaining the theme's visual identity across all views

### Step 5: Document Theme Integration
Add documentation to the project about the applied theme and how to customize it.

## Themes Available

The following 10 themes are available with complete specifications:

### 1. Ocean Depths
**Purpose**: Professional and calming maritime theme  
**Best For**: Enterprise apps, financial dashboards, productivity tools  
**Primary Colors**: Deep blues, teals, navy

### 2. Sunset Boulevard
**Purpose**: Warm and vibrant sunset colors  
**Best For**: Creative platforms, lifestyle apps, social features  
**Primary Colors**: Oranges, warm reds, corals, golds

### 3. Forest Canopy
**Purpose**: Natural and grounded earth tones  
**Best For**: Environmental apps, wellness platforms, nature-focused products  
**Primary Colors**: Greens, browns, mossy tones

### 4. Modern Minimalist
**Purpose**: Clean and contemporary grayscale  
**Best For**: Tech startups, SaaS dashboards, data-heavy applications  
**Primary Colors**: Grays, blacks, whites, subtle accents

### 5. Golden Hour
**Purpose**: Rich and warm autumnal palette  
**Best For**: Photography platforms, design tools, premium products  
**Primary Colors**: Golds, warm browns, burgundies

### 6. Arctic Frost
**Purpose**: Cool and crisp winter-inspired theme  
**Best For**: Modern apps, health/fitness, cool-toned interfaces  
**Primary Colors**: Ice blues, whites, silvers, cool grays

### 7. Desert Rose
**Purpose**: Soft and sophisticated dusty tones  
**Best For**: Beauty platforms, e-commerce, luxury brands  
**Primary Colors**: Dusty rose, mauve, terracotta, cream

### 8. Tech Innovation
**Purpose**: Bold and modern tech aesthetic  
**Best For**: Developer tools, AI platforms, cutting-edge products  
**Primary Colors**: Electric blues, purples, neons, dark backgrounds

### 9. Botanical Garden
**Purpose**: Fresh and organic garden colors  
**Best For**: Plant/gardening apps, health platforms, sustainability  
**Primary Colors**: Fresh greens, botanical accents, natural whites

### 10. Midnight Galaxy
**Purpose**: Dramatic and cosmic deep tones  
**Best For**: Creative tools, entertainment, immersive experiences  
**Primary Colors**: Deep purples, navy, cosmic accents

## Theme Definition Structure

Each theme is defined as a JSON file in the `themes/` directory with the following structure:

```json
{
  "name": "Theme Name",
  "description": "Detailed description of the theme",
  "colors": {
    "primary": "#XXXXXX",
    "secondary": "#XXXXXX",
    "accent": "#XXXXXX",
    "success": "#XXXXXX",
    "warning": "#XXXXXX",
    "error": "#XXXXXX",
    "neutral": {
      "50": "#XXXXXX",
      "100": "#XXXXXX",
      "200": "#XXXXXX",
      "300": "#XXXXXX",
      "400": "#XXXXXX",
      "500": "#XXXXXX",
      "600": "#XXXXXX",
      "700": "#XXXXXX",
      "800": "#XXXXXX",
      "900": "#XXXXXX"
    }
  },
  "fonts": {
    "display": {
      "name": "Font Name",
      "family": "Font family declaration",
      "category": "serif|sans-serif|display"
    },
    "body": {
      "name": "Font Name",
      "family": "Font family declaration",
      "category": "serif|sans-serif"
    }
  },
  "cssVariables": {
    "--color-primary": "#XXXXXX",
    "--color-secondary": "#XXXXXX",
    "--font-display": "'Font Name', serif",
    "--font-body": "'Font Name', sans-serif"
  }
}
```

## Integration with Tailwind CSS

### 1. Update `config/tailwind.config.js`

```javascript
// Get theme file
const theme = require('./.ai/skills/theme-factory/themes/theme-name.json');

module.exports = {
  theme: {
    colors: theme.colors,
    fontFamily: {
      display: theme.fonts.display.family,
      body: theme.fonts.body.family,
    },
    extend: {
      colors: {
        primary: theme.colors.primary,
        secondary: theme.colors.secondary,
        accent: theme.colors.accent,
      }
    },
  }
}
```

### 2. Add CSS Variables to `app/assets/stylesheets/theme.css`

```css
:root {
  --color-primary: #XXXXXX;
  --color-secondary: #XXXXXX;
  --font-display: 'Font Name', serif;
  --font-body: 'Font Name', sans-serif;
}
```

### 3. Use in Phlex Components

```ruby
class Components::Button < Components::Base
  def view_template
    button(
      class: "bg-primary text-white font-display hover:bg-primary/90"
    ) {
      "Click me"
    }
  end
end
```

## Creating Custom Themes

To handle cases where none of the existing themes work for your application:

1. **Gather Input**: Ask about the desired aesthetic, colors, and fonts
2. **Define Colors**: Choose a cohesive color palette with primary, secondary, and accent colors
3. **Select Fonts**: Pick complementary display and body fonts
4. **Create Theme File**: Generate a new theme JSON file in `themes/` directory
5. **Name Appropriately**: Give the theme a descriptive name reflecting its aesthetic
6. **Apply Similar to Built-in Themes**: Use the same integration steps as above

Example custom theme creation:

```json
{
  "name": "Custom Brand",
  "description": "Custom theme for specific brand identity",
  "colors": {
    "primary": "#YOUR_BRAND_COLOR",
    "secondary": "#COMPLEMENT_COLOR",
    "accent": "#HIGHLIGHT_COLOR",
    "neutral": { ... }
  },
  "fonts": {
    "display": {
      "name": "Your Display Font",
      "family": "'Your Font', serif"
    },
    "body": {
      "name": "Your Body Font",
      "family": "'Your Font', sans-serif"
    }
  }
}
```

## Best Practices

1. **Consistency**: Apply themes consistently across all views and components
2. **Contrast**: Ensure sufficient color contrast for accessibility (WCAG 2.1 AA)
3. **Readability**: Test fonts at various sizes and weights
4. **Responsiveness**: Verify theme looks good on all screen sizes
5. **Documentation**: Document theme choices and customizations
6. **Performance**: Minimize CSS file size by only including used colors/fonts
7. **Dark Mode**: Consider providing dark variants of themes when appropriate

## Workflow

1. **Review Themes**: Show user available themes or gather custom requirements
2. **Select Theme**: Get explicit confirmation of choice
3. **Setup Infrastructure**: Update Tailwind config and CSS variables
4. **Apply Across Components**: Use theme colors and fonts in all Phlex components
5. **Test**: Verify consistency and readability
6. **Document**: Record theme details and any customizations

## Reference

- [Tailwind CSS Configuration](https://tailwindcss.com/docs/configuration)
- [CSS Custom Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/--*)
- [Color Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Google Fonts](https://fonts.google.com/)
