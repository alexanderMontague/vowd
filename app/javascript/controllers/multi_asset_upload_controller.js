import { Controller } from "@hotwired/stimulus"

// Uploads several images into the photo library, applying each Turbo Stream response
// so the library grid and the picker options stay in sync without a page reload.
export default class extends Controller {
  static targets = ["input", "status", "progress", "progressBar"]
  static values = {
    purpose: String,
    url: String
  }

  async upload(event) {
    const files = Array.from(event.target.files || [])
    if (!files.length) return

    let completed = 0
    let failed = 0
    let lastError = null
    this.showProgress(0, files.length)

    for (const file of files) {
      try {
        await this.uploadFile(file)
        completed += 1
      } catch (error) {
        failed += 1
        lastError = error
      }
      this.showProgress(completed + failed, files.length)
    }

    if (this.hasInputTarget) this.inputTarget.value = ""

    if (failed > 0) {
      this.setStatus(`Uploaded ${completed} of ${files.length}. ${lastError?.message || "Some uploads failed."}`)
    } else {
      this.setStatus(`Uploaded ${completed}`)
    }
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

  showProgress(done, total) {
    if (this.hasProgressTarget) this.progressTarget.hidden = false
    const percent = total === 0 ? 0 : Math.round((done / total) * 100)
    if (this.hasProgressBarTarget) this.progressBarTarget.style.width = `${percent}%`
    this.setStatus(`Uploading ${done} of ${total}…`)
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
