import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "autosaveSubmit"]
  static values = {
    saving: String
  }

  connect() {
    this.timeout = null
    this.debounceDuration = 1000
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  schedule() {
    if (!this.hasAutosaveSubmitTarget) return

    clearTimeout(this.timeout)

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.savingValue || "Saving..."
    }

    this.timeout = setTimeout(() => {
      this.element.requestSubmit(this.autosaveSubmitTarget)
    }, this.debounceDuration)
  }
}
