import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateEmptyState()

    this.element.addEventListener("house-md:change", this.updateEmptyState)
    this.element.addEventListener("input", this.updateEmptyState)
    this.element.addEventListener("blur", this.updateEmptyState)

    requestAnimationFrame(() => this.updateEmptyState())
  }

  disconnect() {
    this.element.removeEventListener("house-md:change", this.updateEmptyState)
    this.element.removeEventListener("input", this.updateEmptyState)
    this.element.removeEventListener("blur", this.updateEmptyState)
  }

  updateEmptyState = () => {
    const value = typeof this.element.value === "string" ? this.element.value : ""
    const normalizedValue = value.replace(/\u200B/g, "").trim()

    this.element.dataset.empty = normalizedValue.length === 0 ? "true" : "false"
  }
}