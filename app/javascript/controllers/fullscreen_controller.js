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

  async exit(event) {
    if (!this.isFullscreenActive()) return

    event.preventDefault()

    const destination = event.currentTarget.href

    if (document.fullscreenElement) {
      try {
        await document.exitFullscreen()
      } catch {
        // Fall through to navigation even if the browser rejects exit.
      }
    }

    document.documentElement.classList.remove("fullscreen-mode")
    window.location.assign(destination)
  }

  toggleFallbackFullscreen() {
    const element = document.documentElement
    if (element.classList.contains("fullscreen-mode")) {
      element.classList.remove("fullscreen-mode")
    } else {
      element.classList.add("fullscreen-mode")
    }
  }

  isFullscreenActive() {
    return Boolean(document.fullscreenElement) || document.documentElement.classList.contains("fullscreen-mode")
  }
}
