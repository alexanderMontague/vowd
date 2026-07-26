import { Controller } from "@hotwired/stimulus"

// Opens a full-size preview dialog from compact gallery thumbnails.
export default class extends Controller {
  static targets = ["dialog", "image"]

  open(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.fullUrl
    if (!url || !this.hasDialogTarget || !this.hasImageTarget) return

    this.imageTarget.src = url
    this.dialogTarget.showModal()
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  fallbackThumb(event) {
    const image = event.currentTarget
    const fullUrl = image.dataset.fullUrl
    if (!fullUrl || image.src === fullUrl) return

    image.src = fullUrl
  }
}
