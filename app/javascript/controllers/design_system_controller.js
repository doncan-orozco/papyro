import { Controller } from "@hotwired/stimulus"

// toggles category visibility within the design system page
export default class extends Controller {
  static targets = ["category", "tab"]

  connect() {
    // show foundation by default
    this.showCategory("foundation")
  }

  select(event) {
    const cat = event.currentTarget.dataset.category
    this.showCategory(cat)
  }

  showCategory(cat) {
    this.categoryTargets.forEach(el => {
      if (el.dataset.category === cat) {
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
      }
    })

    this.tabTargets.forEach(el => {
      const isActive = el.dataset.category === cat
      el.dataset.state = isActive ? "active" : "inactive"
      el.setAttribute("aria-pressed", isActive ? "true" : "false")
    })
  }
}
