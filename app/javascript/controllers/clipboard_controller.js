import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "feedback"]
  static values = { copied: { type: String, default: "Copied" } }

  async copy() {
    const value = this.hasInputTarget ? this.inputTarget.value : this.element.dataset.copyValue
    if (!value) return

    try {
      await navigator.clipboard.writeText(value)
      this.showFeedback()
    } catch (_error) {
      if (this.hasInputTarget) {
        this.inputTarget.select()
        document.execCommand("copy")
        this.showFeedback()
      }
    }
  }

  showFeedback() {
    if (!this.hasFeedbackTarget) return
    this.feedbackTarget.textContent = this.copiedValue
    this.feedbackTarget.hidden = false
    clearTimeout(this.feedbackTimer)
    this.feedbackTimer = setTimeout(() => {
      this.feedbackTarget.hidden = true
    }, 1800)
  }
}
