import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]
  static values = { activeLocale: String }

  connect() {
    this.render()
  }

  switch(event) {
    this.activeLocaleValue = event.currentTarget.dataset.locale
    this.render()
  }

  render() {
    this.buttonTargets.forEach((button) => {
      const active = button.dataset.locale === this.activeLocaleValue
      button.setAttribute("aria-selected", String(active))
      button.classList.toggle("bg-foreground", active)
      button.classList.toggle("text-background", active)
      button.classList.toggle("text-foreground/70", !active)
      button.classList.toggle("hover:text-foreground", !active)
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.locale !== this.activeLocaleValue
    })
  }
}