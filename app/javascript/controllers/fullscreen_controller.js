import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  toggle(event) {
    event.preventDefault()
    
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {
        // Fallback for browsers that don't support fullscreen
        this.toggleFallbackFullscreen()
      })
    } else {
      document.exitFullscreen()
    }
  }

  toggleFallbackFullscreen() {
    const element = document.documentElement
    if (element.classList.contains("fullscreen-mode")) {
      element.classList.remove("fullscreen-mode")
    } else {
      element.classList.add("fullscreen-mode")
    }
  }
}
