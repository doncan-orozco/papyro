import { Controller } from "@hotwired/stimulus"

/**
 * Theme controller — toggles dark/light mode on the <html> element.
 *
 * Persists the user's preference to localStorage and falls back to the
 * system colour-scheme when no explicit preference has been saved.
 *
 * Usage:
 *   <button data-controller="ui--theme"
 *           data-action="click->ui--theme#toggle"
 *           data-ui--theme-current-value="system">
 *     Toggle theme
 *   </button>
 *
 * Values:
 *   current — "light" | "dark" | "system" (default: "system")
 */
export default class extends Controller {
  static values = { current: { type: String, default: "system" } }

  connect() {
    const saved = localStorage.getItem("papyro-theme")
    if (saved) {
      this.currentValue = saved
    } else {
      this.currentValue = "system"
    }
    this.#apply()
    this.#updateAriaLabel()
  }

  toggle() {
    const isDark = document.documentElement.classList.contains("dark")
    this.currentValue = isDark ? "light" : "dark"
    localStorage.setItem("papyro-theme", this.currentValue)
    this.#apply()
    this.#updateAriaLabel()
    this.dispatch("changed", { detail: { theme: this.currentValue } })
  }

  currentValueChanged() {
    this.#apply()
    this.#updateAriaLabel()
  }

  // ── private ─────────────────────────────────────────────────────────────────

  #apply() {
    const html = document.documentElement
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches

    if (this.currentValue === "dark" || (this.currentValue === "system" && prefersDark)) {
      html.classList.add("dark")
      html.classList.remove("light")
    } else {
      html.classList.remove("dark")
      html.classList.add("light")
    }
  }

  #updateAriaLabel() {
    const isDark = document.documentElement.classList.contains("dark")
    const label = isDark
      ? (this.element.dataset.uiThemeLightLabel || "Switch to light mode")
      : (this.element.dataset.uiThemeDarkLabel  || "Switch to dark mode")
    this.element.setAttribute("aria-label", label)
  }
}
