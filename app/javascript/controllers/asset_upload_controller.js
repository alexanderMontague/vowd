import { Controller } from "@hotwired/stimulus"

// Uploads an image to /admin/website/assets and fills a hidden object_key field.
export default class extends Controller {
  static targets = ["input", "objectKey", "preview", "status"]
  static values = {
    purpose: String,
    url: String
  }

  async upload(event) {
    const file = event.target.files?.[0]
    if (!file) return

    this.setStatus("Uploading…")

    const body = new FormData()
    body.append("file", file)
    body.append("purpose", this.purposeValue)

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          Accept: "application/json"
        },
        body,
        credentials: "same-origin"
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Upload failed")

      this.objectKeyTarget.value = data.object_key
      if (this.hasPreviewTarget) {
        this.previewTarget.src = data.url
        this.previewTarget.hidden = false
      }
      this.setStatus("Uploaded")
    } catch (error) {
      this.setStatus(error.message || "Upload failed")
      if (this.hasInputTarget) this.inputTarget.value = ""
    }
  }

  clear(event) {
    event.preventDefault()
    this.objectKeyTarget.value = ""
    if (this.hasPreviewTarget) {
      this.previewTarget.removeAttribute("src")
      this.previewTarget.hidden = true
    }
    if (this.hasInputTarget) this.inputTarget.value = ""
    this.setStatus("")
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
