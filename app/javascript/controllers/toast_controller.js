import { Controller } from "@hotwired/stimulus"

const EXIT_MS = 220

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 4500 }
  }

  connect() {
    requestAnimationFrame(() => {
      this.element.classList.add("admin-toast--visible")
    })

    if (this.delayValue > 0) {
      this.timeout = window.setTimeout(() => this.dismiss(), this.delayValue)
    }
  }

  disconnect() {
    this.clearTimer()
  }

  dismiss() {
    this.clearTimer()
    this.element.classList.remove("admin-toast--visible")
    this.element.classList.add("admin-toast--leaving")

    window.setTimeout(() => {
      this.element.remove()
    }, EXIT_MS)
  }

  clearTimer() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}
