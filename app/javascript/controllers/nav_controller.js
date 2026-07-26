import { Controller } from "@hotwired/stimulus"

// Past this many pixels the nav is considered lifted off the top of the page.
const LIFT_THRESHOLD = 24
const LIFTED_CLASS = "is-lifted"

// Owns the mobile menu and publishes whether the page has scrolled away from the top.
// Themes that float their nav over a hero use `.is-lifted` to swap in a solid
// background; themes with an always-solid nav simply ignore it.
export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  connect() {
    this.frame = null
    this.trackScroll = this.trackScroll.bind(this)

    window.addEventListener("scroll", this.trackScroll, { passive: true })
    this.syncLift()
  }

  disconnect() {
    window.removeEventListener("scroll", this.trackScroll)
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    this.openIconTarget.classList.toggle("hidden")
    this.closeIconTarget.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }

  trackScroll() {
    if (this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.syncLift()
    })
  }

  syncLift() {
    this.element.classList.toggle(LIFTED_CLASS, window.scrollY > LIFT_THRESHOLD)
  }
}
