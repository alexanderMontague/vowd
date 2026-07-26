import { Controller } from "@hotwired/stimulus"

const PERSIST_DEBOUNCE_MS = 200

const DEVICE_WIDTHS = {
  desktop: "100%",
  tablet: "834px",
  mobile: "390px"
}

// Drives the theme editor's live preview.
//
// Two speeds of feedback, deliberately:
//   - dragging a colour picker writes the authored CSS variables straight into the
//     preview document, which is instant and needs no round trip;
//   - committing a change (releasing the picker, switching theme, toggling a page)
//     posts the draft to the server and reloads the frame, so what you end up looking
//     at is the real server-rendered page rather than an approximation.
//
// Deriving colours (contrast foregrounds especially) is left entirely to the server so
// there is one implementation of it. The preview frame is same-origin, so reading and
// writing its document is allowed.
export default class extends Controller {
  static targets = ["form", "frame", "frameStage", "deviceButton", "pageButton", "status"]
  static values = { previewUrl: String }

  connect() {
    this.persistTimer = null
    this.setDeviceWidth("desktop")
  }

  disconnect() {
    clearTimeout(this.persistTimer)
  }

  // Live, un-committed feedback while a control is being dragged or typed into.
  preview(event) {
    const token = event.target.dataset.themeToken
    if (!token) return

    this.syncPairedInputs(event.target)
    this.writeToken(token, event.target.value)
  }

  // A committed change: persist the draft, then re-render the frame from the server.
  commit() {
    this.setStatus("Updating preview…")
    this.syncPageButtons()

    clearTimeout(this.persistTimer)
    this.persistTimer = setTimeout(() => this.persist({ reload: true }), PERSIST_DEBOUNCE_MS)
  }

  // Switching theme resets colours and fonts to that theme's own defaults; carrying a
  // previous theme's palette across usually looks like a mistake rather than a choice.
  selectTheme(event) {
    const card = event.target.closest("[data-theme-defaults]")
    if (!card) return this.commit()

    const defaults = JSON.parse(card.dataset.themeDefaults)

    Object.entries(defaults.colors || {}).forEach(([role, value]) => {
      this.colorInputs.filter((input) => input.dataset.themeRole === role)
        .forEach((input) => {
          input.value = value
          this.syncPairedInputs(input)
        })
    })

    if (defaults.font) {
      const select = this.fontSelect
      if (select) select.value = defaults.font
    }

    this.commit()
  }

  setDevice(event) {
    this.setDeviceWidth(event.currentTarget.dataset.device)
  }

  openPage(event) {
    event.preventDefault()

    const path = event.currentTarget.dataset.path
    this.pageButtonTargets.forEach((button) => {
      button.classList.toggle("is-active", button === event.currentTarget)
    })

    this.frameTarget.contentWindow.location.assign(path)
  }

  reload() {
    this.reloadFrame()
  }

  // ------------------------------------------------------------------ internals

  async persist({ reload }) {
    // The editor form is a PATCH (Save). Rails method-override would turn this
    // fetch into PATCH /admin/theme/preview, which has no route.
    const body = new FormData(this.formTarget)
    body.delete("_method")

    const response = await fetch(this.previewUrlValue, {
      method: "POST",
      body,
      headers: { "X-CSRF-Token": this.csrfToken, Accept: "application/json" },
      credentials: "same-origin"
    })

    if (!response.ok) {
      this.setStatus("Preview could not be updated")
      return
    }

    this.setStatus("Preview up to date")
    if (reload) this.reloadFrame()
  }

  // Reloading throws away the visitor's scroll position, which makes editing a section
  // halfway down a page miserable. Restore it once the new document is ready.
  reloadFrame() {
    const frame = this.frameTarget
    const offset = frame.contentWindow?.scrollY || 0

    frame.addEventListener("load", () => frame.contentWindow.scrollTo(0, offset), { once: true })
    frame.contentWindow.location.reload()
  }

  writeToken(token, value) {
    this.previewRoot?.style.setProperty(token, value)
  }

  // A colour role has both a picker and a hex field. Whichever one moved updates the
  // other so they never disagree.
  syncPairedInputs(source) {
    const role = source.dataset.themeRole
    if (!role) return

    this.colorInputs
      .filter((input) => input.dataset.themeRole === role && input !== source)
      .forEach((input) => { input.value = source.value })
  }

  // A page switched off has nothing to preview, so its jump button goes with it.
  syncPageButtons() {
    this.pageButtonTargets.forEach((button) => {
      const toggle = this.formTarget.querySelector(`[data-theme-page="${button.dataset.page}"]`)
      if (toggle) button.disabled = !toggle.checked
    })
  }

  setDeviceWidth(device) {
    const width = DEVICE_WIDTHS[device] || DEVICE_WIDTHS.desktop
    this.frameStageTarget.style.maxWidth = width

    this.deviceButtonTargets.forEach((button) => {
      button.classList.toggle("is-active", button.dataset.device === device)
    })
  }

  setStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  get colorInputs() {
    return Array.from(this.formTarget.querySelectorAll("[data-theme-role]"))
  }

  get fontSelect() {
    return this.formTarget.querySelector("[data-theme-font-select]")
  }

  get previewRoot() {
    return this.frameTarget.contentDocument?.documentElement
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
