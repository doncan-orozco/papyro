# frozen_string_literal: true

# Page shell of the parity harness. Same body classes, padding and fonts as react-shadcn-catalog/src/parity/Harness.tsx,
# nothing else. A failed render shows an element with `data-parity-error` (the runner reports PARITY_ERROR).
class Views::DesignSystem::Parity::Show < Views::Base
  FONT_URL = "https://fonts.googleapis.com/css2?family=Fraunces:wght@400;600;700&family=Manrope:wght@400;500;600;700&display=swap"

  # Same value as FONT_STACK in react-shadcn-catalog/src/parity/Harness.tsx (the catalog's Tailwind release has another default).
  FONT_STACK = 'ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"'

  def initialize(html: nil, error: nil)
    @html = html
    @error = error
    super()
  end

  def view_template
    doctype
    html(lang: "en", style: "font-size:16px") do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        title { "parity" }
        link(rel: "stylesheet", href: FONT_URL)
        raw(helpers.stylesheet_link_tag(:app))
        raw(helpers.javascript_importmap_tags)
        style { raw(safe(":root{--font-sans:#{FONT_STACK}}")) }
      end
      # Turbo Drive off: the React harness has no Turbo, so a click on an in-page `#hash` link must not trigger a visit.
      body(class: "bg-background text-foreground", data: { turbo: "false" }) do
        div(class: "p-8") do
          if @error
            div(data: { parity_error: "" }) { @error }
          else
            raw(safe(@html))
          end
        end
      end
    end
  end
end
