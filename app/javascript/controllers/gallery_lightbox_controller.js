import { Controller } from "@hotwired/stimulus"

// Opens a full-size preview dialog from compact gallery thumbnails.
export default class extends Controller {
  static targets = ["dialog", "image", "usage"]

  open(event) {
    event.preventDefault()
    const { fullUrl, assetId } = event.currentTarget.dataset
    if (!fullUrl || !this.hasDialogTarget || !this.hasImageTarget) return

    this.imageTarget.src = fullUrl

    // Names the photo on show so anyone tracking placements can label the preview.
    if (this.hasUsageTarget) this.usageTarget.dataset.assetId = assetId || ""
    this.dispatch("opened")

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
