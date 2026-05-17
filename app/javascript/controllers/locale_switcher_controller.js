import { Controller } from "@hotwired/stimulus"

// Controls the locale dropdown and triggers Turbo navigation or form swap
export default class extends Controller {
  static targets = ["dropdown"]

  connect() {}

  change(event) {
    const contentLocale = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set("content_locale", contentLocale)
    url.searchParams.delete("locale")
    window.Turbo.visit(url.toString())
  }
}
