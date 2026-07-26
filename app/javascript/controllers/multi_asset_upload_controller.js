import { Controller } from "@hotwired/stimulus"

// Multi-file image upload with progress bar; appends compact thumbnail rows.
export default class extends Controller {
  static targets = ["input", "container", "template", "status", "progress", "progressBar"]
  static values = {
    purpose: String,
    url: String,
    placeholder: { type: String, default: "NEW_IMAGE_INDEX" }
  }

  async upload(event) {
    const files = Array.from(event.target.files || [])
    if (!files.length) return

    let completed = 0
    let failed = 0
    this.showProgress(0, files.length)

    for (const [index, file] of files.entries()) {
      try {
        await this.uploadFile(file, index)
        completed += 1
      } catch (_error) {
        failed += 1
      }
      this.showProgress(completed + failed, files.length)
    }

    if (this.hasInputTarget) this.inputTarget.value = ""

    if (failed > 0) {
      this.setStatus(`Uploaded ${completed} of ${files.length} (${failed} failed)`)
    } else {
      this.setStatus(`Uploaded ${completed}`)
    }
  }

  async uploadFile(file, index) {
    const body = new FormData()
    body.append("file", file)
    body.append("purpose", this.purposeValue)

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

    this.appendThumb(data, index)
  }

  appendThumb(data, index) {
    const html = this.templateTarget.innerHTML
      .split(this.placeholderValue)
      .join(String(Date.now() + index))
    this.containerTarget.insertAdjacentHTML("beforeend", html)

    const row = this.containerTarget.lastElementChild
    const objectKeyInput = row.querySelector("input[name*='[object_key]']")
    const preview = row.querySelector("img")
    const openButton = row.querySelector("[data-full-url]")

    if (objectKeyInput) objectKeyInput.value = data.object_key
    if (preview) {
      preview.src = data.thumbnail_url || data.url
      preview.dataset.fullUrl = data.url
    }
    if (openButton) openButton.dataset.fullUrl = data.url
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
