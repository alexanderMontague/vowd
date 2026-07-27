import { Controller } from "@hotwired/stimulus"

const ENTRANCE_OPTIONS = {
  threshold: 0.1,
  rootMargin: "0px 0px -50px 0px"
}

// Middle band of the viewport — the mobile stand-in for hover on single-column
// galleries. Items light up as they scroll through this zone and dim again after.
const FOCUS_OPTIONS = {
  threshold: 0.35,
  rootMargin: "-22% 0px -22% 0px"
}

export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.entranceObserver = new IntersectionObserver(
      (entries) => this.handleEntrance(entries),
      ENTRANCE_OPTIONS
    )

    this.focusObserver = new IntersectionObserver(
      (entries) => this.handleFocus(entries),
      FOCUS_OPTIONS
    )

    this.itemTargets.forEach((element) => {
      this.entranceObserver.observe(element)
      if (element.classList.contains("gallery-item")) {
        this.focusObserver.observe(element)
      }
    })
  }

  disconnect() {
    this.entranceObserver?.disconnect()
    this.focusObserver?.disconnect()
  }

  handleEntrance(entries) {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return

      entry.target.classList.add("visible")
      this.entranceObserver.unobserve(entry.target)
    })
  }

  handleFocus(entries) {
    entries.forEach((entry) => {
      entry.target.classList.toggle("is-active", entry.isIntersecting)
    })
  }
}
