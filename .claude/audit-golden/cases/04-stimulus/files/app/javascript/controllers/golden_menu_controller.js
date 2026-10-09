import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    document.addEventListener("keydown", (event) => this.onKey(event))
    window.setInterval(() => this.refresh(), 5000)
  }

  async refresh() {
    const html = await (await fetch("/menu")).text()
    this.panelTarget.innerHTML = html
    this.badgeTarget.textContent = "Updated"
  }

  onKey(event) {
    if (event.key === "Escape") document.querySelector("#panel").remove()
  }
}
