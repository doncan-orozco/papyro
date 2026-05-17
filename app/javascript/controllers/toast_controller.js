import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 4000 }
  }

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss(event) {
    event?.preventDefault()
    clearTimeout(this.timeout)

    this.element.setAttribute("data-state", "closed")
    this.element.classList.add("opacity-0", "scale-95")

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
