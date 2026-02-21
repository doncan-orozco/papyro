import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  static values = { url: String }

  open(event) {
    event.preventDefault()
    this.dialog = document.createElement("dialog")
    this.dialog.classList.add("lightbox")
    this.dialog.appendChild(this.createImage())
    this.dialog.appendChild(this.createCloseButton())
    document.body.appendChild(this.dialog)
    this.dialog.showModal()
    this.dialog.addEventListener("click", (e) => {
      if (e.target === this.dialog) this.close()
    })
  }

  close() {
    this.dialog?.close()
    this.dialog?.remove()
  }

  createImage() {
    const img = document.createElement("img")
    img.src = this.urlValue
    img.classList.add("lightbox__image")
    img.alt = "Lightbox image"
    return img
  }

  createCloseButton() {
    const btn = document.createElement("button")
    btn.classList.add("lightbox__btn")
    btn.setAttribute("type", "button")
    btn.setAttribute("aria-label", "Close")
    btn.innerHTML = "✕"
    btn.addEventListener("click", () => this.close())
    return btn
  }
}
