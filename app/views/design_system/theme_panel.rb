# frozen_string_literal: true

# Live theme preview for developers (design-system catalog): preset select, radius slider, light/dark, contrast badges
# and "Copy CSS" (a block `bin/rails theme:import` accepts). Nothing is persisted. Behavior: Stimulus `v2--theme-panel`;
# light/dark is the existing `v2--theme` controller. See .ai/skills/shadcn-port/references/theme-contract.md.
class Views::DesignSystem::ThemePanel < Views::Base
  PAIRS = Shadcn::Theme::CONTRAST_PAIRS

  def view_template
    div(
      class: "mx-auto flex max-w-2xl flex-col gap-6 rounded-xl border bg-card p-6 text-card-foreground",
      data: {
        controller: "v2--theme v2--theme-panel",
        action: "v2--theme:changed->v2--theme-panel#refresh",
        v2__theme_panel_presets_value: presets.to_json,
        v2__theme_panel_pairs_value: PAIRS.to_json,
        v2__theme_panel_current_value: current_preset
      }
    ) do
      h2(class: "text-lg font-semibold") { "Theme" }
      controls
      swatches
      div(class: "flex items-center gap-3") do
        button(type: "button", class: button_class, data: { action: "v2--theme-panel#copy" }) { "Copy CSS" }
        span(class: "text-sm text-muted-foreground", data: { v2__theme_panel_target: "status" })
      end
      ul(class: "grid grid-cols-1 gap-1 text-sm sm:grid-cols-2", data: { v2__theme_panel_target: "contrast" })
    end
  end

  private

  def controls
    div(class: "flex flex-wrap items-end gap-4") do
      label(class: "flex flex-col gap-1 text-sm font-medium") do
        plain "Preset"
        select(class: "h-9 rounded-md border border-input bg-transparent px-3 text-sm", data: { v2__theme_panel_target: "preset", action: "change->v2--theme-panel#applyPreset" }) do
          presets.each_key { |name| option(value: name, selected: name == current_preset) { name } }
        end
      end
      label(class: "flex flex-col gap-1 text-sm font-medium") do
        plain "Radius"
        input(type: "range", min: "0", max: "1.5", step: "0.025", value: "0.625", data: { v2__theme_panel_target: "radius", action: "input->v2--theme-panel#applyRadius" })
      end
      div(class: "flex gap-2") do
        %w[Light Dark System].each do |mode|
          button(type: "button", class: button_class, data: { action: "v2--theme##{"set#{mode}"}" }) { mode }
        end
      end
    end
  end

  def swatches
    div(class: "grid grid-cols-2 gap-2 sm:grid-cols-4") do
      %w[background primary secondary muted accent destructive card popover].each do |name|
        div(class: "rounded-md border p-3 text-xs", style: "background: var(--#{name}); color: var(--#{name}-foreground, var(--foreground))") { name }
      end
    end
  end

  def button_class = "inline-flex h-9 items-center rounded-md border border-input bg-background px-3 text-sm font-medium hover:bg-accent hover:text-accent-foreground"

  def current_preset = "zinc"

  # { "slate" => { "root" => {var => value}, "dark" => {...} } } from the presets directory (same files `theme:use` reads).
  def presets
    @presets ||= Shadcn::Theme.presets.to_h do |name|
      palette = Shadcn::Theme.parse(File.read(File.join(Shadcn::Theme.presets_dir, "#{name}.css")))
      [ name, { root: palette.root, dark: palette.dark } ]
    end
  end
end
