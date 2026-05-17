import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "input"]

  static values = {
    alt: String,
    imageClass: String
  }

  connect() {
    this.objectUrl = null
  }

  disconnect() {
    this.revokeObjectUrl()
  }

  preview() {
    const file = this.inputTarget.files?.[0]
    if (!file || !file.type.startsWith("image/")) return

    this.revokeObjectUrl()
    this.objectUrl = URL.createObjectURL(file)

    const image = document.createElement("img")
    image.src = this.objectUrl
    image.alt = this.altValue
    image.className = this.imageClassValue

    this.canvasTarget.replaceChildren(image)
  }

  revokeObjectUrl() {
    if (!this.objectUrl) return

    URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }
}
