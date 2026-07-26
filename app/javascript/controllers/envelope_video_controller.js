import { Controller } from "@hotwired/stimulus"

// Uploads the invitation envelope video; the server compresses it, captures the
// first-frame poster, and Turbo-replaces this section with the new placement.
export default class extends Controller {
  static targets = ["input", "status", "progress", "progressBar", "preview", "empty", "poster", "assetId"]
  static values = {
    purpose: String,
    url: String
  }

  async upload(event) {
    const file = event.target.files?.[0]
    if (!file) return

    this.showProgress(true)
    this.setStatus("Uploading and compressing…")

    try {
      await this.uploadFile(file)
    } catch (error) {
      this.setStatus(error.message || "Upload failed")
      this.showProgress(false)
    }

    if (this.hasInputTarget) this.inputTarget.value = ""
  }

  async uploadFile(file) {
    const body = new FormData()
    body.append("file", file)
    body.append("purpose", this.purposeValue)

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
        Accept: "text/vnd.turbo-stream.html, application/json"
      },
      body,
      credentials: "same-origin"
    })

    if (!response.ok) throw new Error(await this.errorMessage(response))

    window.Turbo.renderStreamMessage(await response.text())
  }

  async errorMessage(response) {
    try {
      const data = await response.json()
      return data.error || "Upload failed"
    } catch (_error) {
      return "Upload failed"
    }
  }

  showProgress(visible) {
    if (this.hasProgressTarget) this.progressTarget.hidden = !visible
    if (visible && this.hasProgressBarTarget) this.progressBarTarget.style.width = "60%"
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
