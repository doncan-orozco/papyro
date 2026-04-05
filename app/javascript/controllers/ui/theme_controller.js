import { Controller } from "@hotwired/stimulus"

/**
 * Theme controller — Light / Dark / System preference with prefers-color-scheme.
 *
 * "System" is the default: no explicit class on <html>, the OS preference is
 * honoured automatically by the CSS @media (prefers-color-scheme: dark) block.
 * The controller also mirrors the OS state into html.dark so that Tailwind
 * `dark:` utility classes work in system mode.
 *
 * "Light" / "Dark" add an explicit html.light / html.dark class that overrides
 * the media query and persists the choice to localStorage ("papyro-theme").
 * Removing the key (choosing System) reverts to OS tracking.
 *
 * Usage — place data-controller on any wrapper wrapping the toggle:
 *   <div data-controller="ui--theme"> … </div>
 *
 * Setter actions (for dropdown items):
 *   data-action="click->ui--theme#setLight"
 *   data-action="click->ui--theme#setDark"
 *   data-action="click->ui--theme#setSystem"
 *
 * HTML side-effects (on <html>):
 *   class="dark"        — present whenever dark mode is active (explicit OR system)
 *   class="light"       — present when user forces light on a dark OS
 *   data-theme          — "light" | "dark" | "system" (drives CSS active-state checks)
 */
export default class extends Controller {
  static values = { current: { type: String, default: "system" } }

  #mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
  #systemListener = null

  connect() {
    this.currentValue = localStorage.getItem("papyro-theme") || "system"
    this.#apply()
    this.#watchSystem()
  }

  disconnect() {
    this.#unwatchSystem()
  }

  // Cycle: system → light → dark → system
  toggle() {
    const cycle = { system: "light", light: "dark", dark: "system" }
    this.#set(cycle[this.currentValue] ?? "system")
  }

  setLight()  { this.#set("light")  }
  setDark()   { this.#set("dark")   }
  setSystem() { this.#set("system") }

  // ── private ─────────────────────────────────────────────────────────────────

  #set(theme) {
    this.currentValue = theme
    if (theme === "system") {
      localStorage.removeItem("papyro-theme")
    } else {
      localStorage.setItem("papyro-theme", theme)
    }
    this.#apply()
    this.#watchSystem()
    this.dispatch("changed", { detail: { theme } })
  }

  #apply() {
    const html = document.documentElement
    const osDark = this.#mediaQuery.matches

    if (this.currentValue === "dark" || (this.currentValue === "system" && osDark)) {
      html.classList.add("dark")
      html.classList.remove("light")
    } else if (this.currentValue === "light") {
      html.classList.add("light")
      html.classList.remove("dark")
    } else {
      // system + OS light: remove explicit classes, CSS media query is inactive
      html.classList.remove("dark", "light")
    }

    // data-theme drives active-state styling in the theme toggle dropdown
    html.dataset.theme = this.currentValue
  }

  #watchSystem() {
    this.#unwatchSystem()
    if (this.currentValue === "system") {
      this.#systemListener = () => this.#apply()
      this.#mediaQuery.addEventListener("change", this.#systemListener)
    }
  }

  #unwatchSystem() {
    if (this.#systemListener) {
      this.#mediaQuery.removeEventListener("change", this.#systemListener)
      this.#systemListener = null
    }
  }
}
