import { Controller } from "@hotwired/stimulus"

// Off-canvas admin side nav on small screens; desktop rail stays always visible.
export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    this.onNavigate = this.onNavigate.bind(this)
    document.addEventListener("keydown", this.onKeydown)
    document.addEventListener("turbo:before-visit", this.onNavigate)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    document.removeEventListener("turbo:before-visit", this.onNavigate)
    this.unlockBody()
  }

  open() {
    this.element.classList.add("is-nav-open")
    if (this.hasBackdropTarget) this.backdropTarget.hidden = false
    this.lockBody()
  }

  close() {
    this.element.classList.remove("is-nav-open")
    if (this.hasBackdropTarget) this.backdropTarget.hidden = true
    this.unlockBody()
  }

  onKeydown(event) {
    if (event.key === "Escape") this.close()
  }

  onNavigate() {
    this.close()
  }

  lockBody() {
    document.documentElement.classList.add("admin-nav-locked")
  }

  unlockBody() {
    document.documentElement.classList.remove("admin-nav-locked")
  }
}
