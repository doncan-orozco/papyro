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
    clearTimeout(this.timeout)

    const statusElement = this.hasStatusTarget ? this.statusTarget : document.getElementById("autosave-status")

    if (statusElement) {
      statusElement.innerHTML = `
        <span class="inline-flex items-center justify-end gap-1.5 text-muted-foreground/70">
          <svg class="h-3.5 w-3.5 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden="true">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          ${this.savingValue || "Saving..."}
        </span>
      `
    }

    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceDuration)
  }
}