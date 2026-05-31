import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "localeInput"]
  static values = { activeLocale: String }

  connect() {
    if (this.hasLocaleInputTarget && this.activeLocaleValue) {
      this.localeInputTarget.value = this.activeLocaleValue
    }
  }

  switch(event) {
    event.preventDefault()

    const locale = event.currentTarget.dataset.locale
    if (!locale) return

    const url = new URL(window.location.href)
    url.searchParams.set("content_locale", locale)

    window.location.assign(url.toString())
  }
}