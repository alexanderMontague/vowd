import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "vowd-admin-scroll"

// Remembers window scroll across form saves that redirect back to the same path
// (theme/website section editors). Scoped to pathname so jumping sections does not
// inherit another page's offset.
export default class extends Controller {
  connect() {
    this.persistBound = () => this.persist()
    this.restoreBound = () => this.restore()

    this.element.addEventListener("submit", this.persistBound, true)
    document.addEventListener("turbo:load", this.restoreBound)
    this.restore()
  }

  disconnect() {
    this.element.removeEventListener("submit", this.persistBound, true)
    document.removeEventListener("turbo:load", this.restoreBound)
  }

  persist() {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify({
      path: window.location.pathname,
      y: window.scrollY
    }))
  }

  restore() {
    const raw = sessionStorage.getItem(STORAGE_KEY)
    if (!raw) return

    sessionStorage.removeItem(STORAGE_KEY)

    let saved
    try {
      saved = JSON.parse(raw)
    } catch (_error) {
      return
    }

    if (!saved || saved.path !== window.location.pathname) return

    const y = Number(saved.y)
    if (!Number.isFinite(y) || y <= 0) return

    requestAnimationFrame(() => window.scrollTo(0, y))
  }
}
