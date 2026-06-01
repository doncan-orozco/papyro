import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  static values = { url: String }

  connect() {
    this.element.dataset.lightboxReady = "true"
  }

  disconnect() {
    this.close({ restoreFocus: false })
    delete this.element.dataset.lightboxReady
  }

  open(event) {
    event.preventDefault()
    this.close({ restoreFocus: false })

    const trigger = event.currentTarget
    this.triggerElement = trigger instanceof HTMLElement ? trigger : null
    const resolvedUrl =
      trigger?.dataset.lightboxUrlValue ||
      trigger?.getAttribute("href") ||
      this.urlValue
    const resolvedAlt =
      trigger?.querySelector("img")?.getAttribute("alt") ||
      "Lightbox image"

    if (!resolvedUrl) return

    this.dialog = document.createElement("dialog")
    this.dialog.classList.add("lightbox")
    this.dialog.appendChild(this.createImage(resolvedUrl, resolvedAlt))
    this.dialog.appendChild(this.createCloseButton())
    document.body.appendChild(this.dialog)

    this.handleBackdropClick = (e) => {
      if (e.target === this.dialog) this.close()
    }
    this.handleCancel = (e) => {
      e.preventDefault()
      this.close()
    }
    this.handleKeydown = (e) => {
      if (e.key === "Escape") {
        e.preventDefault()
        this.close()
      }
    }

    this.dialog.addEventListener("click", this.handleBackdropClick)
    this.dialog.addEventListener("cancel", this.handleCancel)
    document.addEventListener("keydown", this.handleKeydown)

    this.lockScroll()
    this.dialog.showModal()
  }

  close({ restoreFocus = true } = {}) {
    if (!this.dialog) return

    this.dialog.removeEventListener("click", this.handleBackdropClick)
    this.dialog.removeEventListener("cancel", this.handleCancel)
    document.removeEventListener("keydown", this.handleKeydown)
    if (this.dialog.open) this.dialog.close()
    this.dialog.remove()

    this.unlockScroll()

    const triggerToFocus = this.triggerElement
    if (restoreFocus && triggerToFocus && document.contains(triggerToFocus)) {
      requestAnimationFrame(() => triggerToFocus.focus())
    }

    this.dialog = null
    this.triggerElement = null
    this.handleBackdropClick = null
    this.handleCancel = null
    this.handleKeydown = null
  }

  lockScroll() {
    if (this.scrollLockState) return

    const root = document.documentElement
    const body = document.body
    const computedPadding = Number.parseFloat(window.getComputedStyle(body).paddingRight) || 0
    const scrollbarWidth = Math.max(0, window.innerWidth - root.clientWidth)

    this.scrollLockState = {
      bodyPaddingRight: body.style.paddingRight,
      htmlOverflow: root.style.overflow,
      bodyOverflow: body.style.overflow
    }

    root.classList.add("lightbox-open")
    body.classList.add("lightbox-open")
    root.style.overflow = "hidden"
    body.style.overflow = "hidden"

    if (scrollbarWidth > 0) {
      body.style.paddingRight = `${computedPadding + scrollbarWidth}px`
    }
  }

  unlockScroll() {
    if (!this.scrollLockState) return

    const root = document.documentElement
    const body = document.body

    root.classList.remove("lightbox-open")
    body.classList.remove("lightbox-open")
    root.style.overflow = this.scrollLockState.htmlOverflow
    body.style.overflow = this.scrollLockState.bodyOverflow
    body.style.paddingRight = this.scrollLockState.bodyPaddingRight

    this.scrollLockState = null
  }

  createImage(url, altText) {
    const img = document.createElement("img")
    img.src = url
    img.classList.add("lightbox__image")
    img.alt = altText
    return img
  }

  createCloseButton() {
    const btn = document.createElement("button")
    btn.classList.add("lightbox__btn")
    btn.setAttribute("type", "button")
    btn.setAttribute("aria-label", "Close image")

    const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    icon.setAttribute("viewBox", "0 0 24 24")
    icon.setAttribute("aria-hidden", "true")

    const lineA = document.createElementNS("http://www.w3.org/2000/svg", "path")
    lineA.setAttribute("d", "M18 6 6 18")
    lineA.setAttribute("stroke", "currentColor")
    lineA.setAttribute("stroke-width", "2")
    lineA.setAttribute("stroke-linecap", "round")
    lineA.setAttribute("stroke-linejoin", "round")

    const lineB = document.createElementNS("http://www.w3.org/2000/svg", "path")
    lineB.setAttribute("d", "m6 6 12 12")
    lineB.setAttribute("stroke", "currentColor")
    lineB.setAttribute("stroke-width", "2")
    lineB.setAttribute("stroke-linecap", "round")
    lineB.setAttribute("stroke-linejoin", "round")

    icon.append(lineA, lineB)
    btn.appendChild(icon)
    btn.addEventListener("click", () => this.close())
    return btn
  }
}
