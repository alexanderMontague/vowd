import { Controller } from "@hotwired/stimulus"

const MESSAGE_SOURCE = "vowd-site-editor"

// Runs inside the guest-site iframe when the Theme editor is active.
export default class extends Controller {
  static targets = ["hotspot"]

  connect() {
    this.active = null
    this.boundPointer = this.onPointerDown.bind(this)
    this.element.addEventListener("click", this.boundPointer, true)
    this.post({ type: "preview-ready", path: window.location.pathname })
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundPointer, true)
    this.finishEdit(false)
  }

  onPointerDown(event) {
    // Site menu must keep working — never hijack nav / footer links.
    if (event.target.closest(".wedding-nav a, .wedding-nav button, .wedding-footer a")) return

    const hotspot = event.target.closest("[data-site-editor-target='hotspot']")
    if (!hotspot || !this.element.contains(hotspot)) return

    if (this.active === hotspot && hotspot.isContentEditable) return

    event.preventDefault()
    event.stopPropagation()

    const kind = hotspot.dataset.kind

    if (kind === "text") {
      this.beginTextEdit(hotspot)
      return
    }

    if (kind === "slot") {
      this.post({ type: "open-slot", slot: hotspot.dataset.slot })
      return
    }

    if (kind === "panel") {
      this.post({ type: "open-panel", panel: hotspot.dataset.panel })
      return
    }

    if (kind === "essentials") {
      this.post({ type: "open-essentials", href: hotspot.dataset.href })
    }
  }

  beginTextEdit(hotspot) {
    this.finishEdit(false)
    this.active = hotspot
    this.original = hotspot.innerText
    hotspot.classList.add("is-editing")
    hotspot.contentEditable = "plaintext-only"
    if (hotspot.contentEditable !== "plaintext-only") hotspot.contentEditable = "true"
    hotspot.focus()

    const range = document.createRange()
    range.selectNodeContents(hotspot)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)

    this.onBlur = () => this.finishEdit(true)
    this.onKey = (event) => {
      if (event.key === "Escape") {
        hotspot.innerText = this.original
        this.finishEdit(false)
      }
      if (event.key === "Enter" && hotspot.dataset.multiline !== "true") {
        event.preventDefault()
        hotspot.blur()
      }
    }

    hotspot.addEventListener("blur", this.onBlur)
    hotspot.addEventListener("keydown", this.onKey)
  }

  finishEdit(save) {
    if (!this.active) return

    const hotspot = this.active
    hotspot.removeEventListener("blur", this.onBlur)
    hotspot.removeEventListener("keydown", this.onKey)
    hotspot.contentEditable = "false"
    hotspot.classList.remove("is-editing")

    const value = hotspot.innerText.trim()
    const field = hotspot.dataset.field

    this.active = null
    this.onBlur = null
    this.onKey = null

    if (save && field && value !== (this.original || "").trim()) {
      this.post({ type: "save-text", field, value })
    }
  }

  post(payload) {
    window.parent.postMessage({ source: MESSAGE_SOURCE, ...payload }, window.location.origin)
  }
}
