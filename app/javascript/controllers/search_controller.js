import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "panel", "results"]

  connect() {
    this.debounceTimer = null
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this)
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    this.boundHandleEscape = this.handleEscape.bind(this)
    this.boundHandleFrameLoad = this.handleFrameLoad.bind(this)

    document.addEventListener("keydown", this.boundHandleGlobalKeydown)
    document.addEventListener("turbo:frame-load", this.boundHandleFrameLoad)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown)
    document.removeEventListener("turbo:frame-load", this.boundHandleFrameLoad)
    this.removePanelListeners()
    clearTimeout(this.debounceTimer)
  }

  search(event) {
    clearTimeout(this.debounceTimer)
    const query = event.target.value.trim()

    if (query.length === 0) {
      this.closePanel()
      return
    }

    this.openPanel()
    this.debounceTimer = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }

  openPanel() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.remove("hidden")
      document.addEventListener("click", this.boundHandleClickOutside)
    }
  }

  closePanel() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.add("hidden")
    }
    this.removePanelListeners()
  }

  handleGlobalKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      event.stopPropagation()
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.closePanel()
      this.inputTarget.blur()
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closePanel()
    }
  }

  handleFrameLoad(event) {
    if (event.target.id !== "search_results") return

    const frame = event.target
    const hasContent = frame.textContent.trim().length > 0
    if (hasContent) {
      this.openPanel()
    }
  }

  removePanelListeners() {
    document.removeEventListener("click", this.boundHandleClickOutside)
  }
}
