import { Controller } from "@hotwired/stimulus"

// Light / Dark / System. shadcn themes need only `.dark` on <html> (light is its absence), so this
// controller toggles that single class and mirrors the OS preference into it when the choice is "system".
// The choice persists in localStorage under `storageKey` (default "shadcn-theme"); a pre-paint script that avoids the flash of the
// wrong theme has to read the same key. Storage that throws (private windows, blocked site data) degrades to the system preference.
//
//   <div data-controller="shadcn--theme" data-shadcn--theme-storage-key-value="my-app-theme">
//     <button data-action="shadcn--theme#setLight">...</button>  setDark / setSystem / toggle
export default class extends Controller {
  static values = {
    current: { type: String, default: "system" },
    storageKey: { type: String, default: "shadcn-theme" }
  }

  #mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
  #systemListener = () => this.#apply()

  connect() {
    this.currentValue = this.#read()
    this.#apply()
    this.#mediaQuery.addEventListener("change", this.#systemListener)
  }

  disconnect() {
    this.#mediaQuery.removeEventListener("change", this.#systemListener)
  }

  // Cycle: system -> light -> dark -> system
  toggle() {
    const cycle = { system: "light", light: "dark", dark: "system" }
    this.#set(cycle[this.currentValue] ?? "system")
  }

  setLight() { this.#set("light") }
  setDark() { this.#set("dark") }
  setSystem() { this.#set("system") }

  #set(theme) {
    this.currentValue = theme
    this.#write(theme)
    this.#apply()
    this.dispatch("changed", { detail: { theme } })
  }

  // The stored choice when it is "light" or "dark"; anything else (nothing stored, a stale value, blocked storage) is "system".
  #read() {
    try {
      const stored = localStorage.getItem(this.storageKeyValue)
      return stored === "light" || stored === "dark" ? stored : "system"
    } catch {
      return "system"
    }
  }

  #write(theme) {
    try {
      if (theme === "system") localStorage.removeItem(this.storageKeyValue)
      else localStorage.setItem(this.storageKeyValue, theme)
    } catch {
      // storage unavailable: the choice applies to this page only
    }
  }

  #apply() {
    const html = document.documentElement
    const dark = this.currentValue === "dark" || (this.currentValue === "system" && this.#mediaQuery.matches)
    html.classList.toggle("dark", dark)
    html.dataset.theme = this.currentValue
  }
}
