import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    body: String,
    titleSelector: String,
    bodySelector: String
  }

  apply() {
    this.copyValue(this.titleSelectorValue, this.titleValue)
    this.copyValue(this.bodySelectorValue, this.bodyValue)
  }

  copyValue(selector, value) {
    const field = document.querySelector(selector)
    if (!field) return

    field.value = value
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.dispatchEvent(new Event("change", { bubbles: true }))
  }
}