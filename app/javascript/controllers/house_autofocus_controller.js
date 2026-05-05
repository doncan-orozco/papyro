import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (!this.element.hasAttribute("autofocus")) {
      return
    }

    requestAnimationFrame(() => {
      setTimeout(() => this.applyAutofocus(), 0)
    })
  }

  applyAutofocus() {
    if (typeof this.element.focus === "function") {
      this.element.focus()
    }

    const value = this.editorValue()
    if (typeof value !== "string") {
      return
    }

    const selection = this.element?.document?.selection
    if (selection?.select) {
      selection.select({ start: value.length, end: value.length })
    }
  }

  editorValue() {
    return this.element.value ?? this.element.textContent ?? ""
  }
}
