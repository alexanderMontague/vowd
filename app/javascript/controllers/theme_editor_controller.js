import { Controller } from "@hotwired/stimulus"

const PERSIST_DEBOUNCE_MS = 200
const AUTOSAVE_DEBOUNCE_MS = 450
const MESSAGE_SOURCE = "vowd-site-editor"

const DEVICE_WIDTHS = {
  desktop: "100%",
  tablet: "834px",
  mobile: "390px"
}

const PANEL_TITLES = {
  look: "Theme",
  photos: "Photos",
  home_settings: "Home",
  home: "Home",
  faq: "FAQ",
  wedding_party: "Wedding party",
  save_the_date: "Save the Date",
  rsvp: "RSVP"
}

const FIELD_SECTION = {
  "hero.tagline": "home",
  "story.title": "home",
  "story.closing": "home",
  "story.paragraphs": "home",
  "photos_page.homepage_title": "home",
  "photos_page.title": "photos",
  "photos_page.subtitle": "photos",
  "rsvp_copy.title": "rsvp",
  "rsvp_copy.description": "rsvp",
  "rsvp_copy.button_text": "rsvp",
  "rsvp_copy.lookup_hint": "rsvp",
  "save_the_date_copy.eyebrow": "save_the_date",
  "save_the_date_copy.announcement": "save_the_date",
  "save_the_date_copy.formal_note": "save_the_date",
  "save_the_date_copy.calendar_button_text": "save_the_date",
  "save_the_date_copy.signup_eyebrow": "save_the_date",
  "save_the_date_copy.signup_prompt": "save_the_date",
  "save_the_date_copy.submit_button_text": "save_the_date",
  "faq.title": "faq",
  "faq.subtitle": "faq",
  "wedding_party.title": "wedding_party",
  "wedding_party.subtitle": "wedding_party",
  "wedding_party.bridesmaids_title": "wedding_party",
  "wedding_party.groomsmen_title": "wedding_party"
}

const FIELD_INPUT_NAME = {
  "hero.tagline": "wedding[hero][tagline]",
  "story.title": "wedding[story][title]",
  "story.closing": "wedding[story][closing]",
  "story.paragraphs": "wedding[story][paragraphs_text]",
  "photos_page.title": "wedding[photos_page][title]",
  "photos_page.subtitle": "wedding[photos_page][subtitle]",
  "photos_page.homepage_title": "wedding[photos_page][homepage_title]",
  "rsvp_copy.title": "wedding[rsvp_copy][title]",
  "rsvp_copy.description": "wedding[rsvp_copy][description]",
  "rsvp_copy.button_text": "wedding[rsvp_copy][button_text]",
  "rsvp_copy.lookup_hint": "wedding[rsvp_copy][lookup_hint]",
  "save_the_date_copy.eyebrow": "wedding[save_the_date_copy][eyebrow]",
  "save_the_date_copy.announcement": "wedding[save_the_date_copy][announcement]",
  "save_the_date_copy.formal_note": "wedding[save_the_date_copy][formal_note]",
  "save_the_date_copy.calendar_button_text": "wedding[save_the_date_copy][calendar_button_text]",
  "save_the_date_copy.signup_eyebrow": "wedding[save_the_date_copy][signup_eyebrow]",
  "save_the_date_copy.signup_prompt": "wedding[save_the_date_copy][signup_prompt]",
  "save_the_date_copy.submit_button_text": "wedding[save_the_date_copy][submit_button_text]",
  "faq.title": "wedding[faq][title]",
  "faq.subtitle": "wedding[faq][subtitle]",
  "wedding_party.title": "wedding[wedding_party][title]",
  "wedding_party.subtitle": "wedding[wedding_party][subtitle]",
  "wedding_party.bridesmaids_title": "wedding[wedding_party][bridesmaids_title]",
  "wedding_party.groomsmen_title": "wedding[wedding_party][groomsmen_title]"
}

const INVITATION_SECTIONS = new Set(["save_the_date", "rsvp"])
const SKIP_VIDEO_STORAGE_KEY = "vowd-theme-editor-skip-video"

// Full-bleed preview + drawer. Content autosaves; Theme (look) drafts until Save.
export default class extends Controller {
  static targets = [
    "lookForm", "contentForm", "frame", "frameStage", "deviceButton", "status",
    "drawer", "backdrop", "drawerTitle", "toastStack", "slotPickers",
    "panel", "lookFooter", "pageTab", "themeTab", "frameLoading",
    "skipVideoControl", "skipVideo"
  ]
  static values = {
    previewUrl: String,
    saveUrl: String,
    lookUrl: String,
    section: String,
    essentialsUrl: String,
    pages: Object,
    sectionUrls: Object
  }

  connect() {
    this.persistTimer = null
    this.autosaveTimer = null
    this.activePickerEl = null
    this.pickerSnapshot = null
    this.drawerMode = "page"
    this.ensuringSkipVideo = false
    this.lastSyncedPath = null
    this.currentPanel = this.defaultPanelFor(this.sectionValue)
    this.boundMessage = this.onFrameMessage.bind(this)
    this.boundFrameLoad = this.onFrameLoad.bind(this)
    window.addEventListener("message", this.boundMessage)
    if (this.hasFrameTarget) this.frameTarget.addEventListener("load", this.boundFrameLoad)
    this.setDeviceWidth("desktop")
    this.restoreSkipVideoPreference()
    this.updateSkipVideoControl(this.sectionValue)
    this.framePathTimer = window.setInterval(() => this.syncFromFrameLocation(), 600)
  }

  disconnect() {
    clearTimeout(this.persistTimer)
    clearTimeout(this.autosaveTimer)
    clearInterval(this.framePathTimer)
    window.removeEventListener("message", this.boundMessage)
    if (this.hasFrameTarget) this.frameTarget.removeEventListener("load", this.boundFrameLoad)
    document.body.classList.remove("theme-editor-drawer-open")
  }

  preview(event) {
    const token = event.target.dataset.themeToken
    if (!token) return

    this.syncPairedInputs(event.target)
    this.writeToken(token, event.target.value)
  }

  commit() {
    this.setStatus("Updating preview…")
    clearTimeout(this.persistTimer)
    this.persistTimer = setTimeout(() => this.persist({ reload: true }), PERSIST_DEBOUNCE_MS)
  }

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

    if (defaults.font && this.fontSelect) this.fontSelect.value = defaults.font

    this.commit()
  }

  setDevice(event) {
    this.setDeviceWidth(event.currentTarget.dataset.device)
  }

  reload() {
    this.reloadFrame()
  }

  openSettings(event) {
    event?.preventDefault()
    this.openDrawerFor(this.currentPanel || this.defaultPanelFor(this.sectionValue), { mode: "page" })
  }

  showPageTab(event) {
    event?.preventDefault()
    this.openDrawerFor(this.currentPanel || this.defaultPanelFor(this.sectionValue), { mode: "page" })
  }

  showThemeTab(event) {
    event?.preventDefault()
    this.openDrawerFor("look", { mode: "theme" })
  }

  openDrawer(event) {
    const panel = event.currentTarget?.dataset?.panel || this.currentPanel
    this.openDrawerFor(panel)
  }

  openDrawerFor(panel, { mode } = {}) {
    const nextPanel = panel || "home_settings"
    this.drawerMode = mode || (nextPanel === "look" ? "theme" : "page")

    if (this.drawerMode === "page" && nextPanel !== "look") {
      this.currentPanel = nextPanel
    }

    const visiblePanel = this.drawerMode === "theme" ? "look" : this.currentPanel
    this.showPanel(visiblePanel)
    this.syncDrawerTabs()

    if (this.hasDrawerTitleTarget) {
      this.drawerTitleTarget.textContent = PANEL_TITLES[this.currentPanel] || "Page"
    }

    const isTheme = this.drawerMode === "theme"
    if (this.hasLookFooterTarget) this.lookFooterTarget.hidden = !isTheme

    this.drawerTarget.classList.add("is-open")
    this.drawerTarget.setAttribute("aria-hidden", "false")
    if (this.hasBackdropTarget) this.backdropTarget.hidden = false
    document.body.classList.add("theme-editor-drawer-open")
  }

  syncDrawerTabs() {
    const pageActive = this.drawerMode === "page"
    if (this.hasPageTabTarget) {
      this.pageTabTarget.classList.toggle("is-active", pageActive)
      this.pageTabTarget.setAttribute("aria-selected", pageActive ? "true" : "false")
    }
    if (this.hasThemeTabTarget) {
      this.themeTabTarget.classList.toggle("is-active", !pageActive)
      this.themeTabTarget.setAttribute("aria-selected", pageActive ? "false" : "true")
    }
  }

  closeDrawer() {
    this.drawerTarget.classList.remove("is-open")
    this.drawerTarget.setAttribute("aria-hidden", "true")
    if (this.hasBackdropTarget) this.backdropTarget.hidden = true
    if (this.hasLookFooterTarget) this.lookFooterTarget.hidden = true
    document.body.classList.remove("theme-editor-drawer-open")
  }

  showPanel(panel) {
    this.panelTargets.forEach((element) => {
      const active = element.dataset.panel === panel
      element.hidden = !active
      element.classList.toggle("is-active", active)
    })
  }

  autosaveFormDebounced(event) {
    // Look & feel theme fields draft until Save; the share-image content form
    // inside the Theme tab still autosaves like other page panels.
    const form = event?.target?.closest("form")
    if (form && this.hasLookFormTarget && form === this.lookFormTarget) return

    clearTimeout(this.autosaveTimer)
    this.autosaveTimer = setTimeout(() => this.autosaveForm(event), AUTOSAVE_DEBOUNCE_MS)
  }

  autosaveForm(event) {
    const form = event?.target?.closest("form") || this.activeContentForm
    if (!form) return
    this.patchWedding(new FormData(form), { reload: true, toast: "Saved" })
  }

  onPickerOpened(event) {
    this.activePickerEl = event.detail?.picker || null
    this.pickerSnapshot = this.pickerSelectionSignature(this.activePickerEl)
  }

  onPickerClosed() {
    const picker = this.activePickerEl
    const snapshot = this.pickerSnapshot
    this.activePickerEl = null
    this.pickerSnapshot = null

    // No open snapshot → ignore (or open/close with nothing to compare).
    if (!picker || snapshot == null) return

    const next = this.pickerSelectionSignature(picker)
    if (next === snapshot) return

    const form = picker.closest("form.theme-editor-form")

    if (form && (!this.hasLookFormTarget || form !== this.lookFormTarget)) {
      this.mirrorPlacementPickers(form, this.hasSlotPickersTarget ? this.slotPickersTarget : null)
      this.patchWedding(new FormData(form), { reload: true, toast: "Photo updated" })
      return
    }

    this.saveSlotPicker()
  }

  pickerSelectionSignature(picker) {
    if (!picker) return ""

    return Array.from(picker.querySelectorAll("[data-asset-picker-target='selected']"))
      .map((el) => el.dataset.assetId)
      .filter(Boolean)
      .sort()
      .join(",")
  }

  onFrameLoad() {
    this.hideFrameLoading()
    this.ensuringSkipVideo = false
    this.syncFromFrameLocation({ force: true })
  }

  syncFromFrameLocation({ force = false } = {}) {
    if (!this.hasFrameTarget) return

    try {
      const path = this.frameTarget.contentWindow?.location?.pathname
      if (!path) return
      if (!force && path === this.lastSyncedPath) return

      this.lastSyncedPath = path
      this.syncFromPreviewPath(path)
    } catch (_error) {
      // Cross-origin should not happen on same-origin preview.
    }
  }

  onFrameMessage(event) {
    if (event.origin !== window.location.origin) return
    const data = event.data
    if (!data || data.source !== MESSAGE_SOURCE) return

    switch (data.type) {
      case "preview-ready":
        this.lastSyncedPath = data.path
        this.syncFromPreviewPath(data.path)
        break
      case "save-text":
        this.saveTextField(data.field, data.value)
        break
      case "open-slot":
        this.openSlotPicker(data.slot)
        break
      case "open-panel":
        this.openDrawerFor(data.panel, { mode: "page" })
        break
      case "open-essentials":
        window.top.location.assign(this.essentialsUrlValue || data.href)
        break
      default:
        break
    }
  }

  syncFromPreviewPath(path) {
    if (!path) return

    const section = this.sectionForPath(path)
    this.updateSkipVideoControl(section || this.sectionValue)

    if (!section) return

    this.currentPanel = this.defaultPanelFor(section)
    this.syncAdminUrl(section)

    if (this.drawerTarget.classList.contains("is-open") && this.drawerMode === "page") {
      this.showPanel(this.currentPanel)
      if (this.hasDrawerTitleTarget) {
        this.drawerTitleTarget.textContent = PANEL_TITLES[this.currentPanel] || "Page"
      }
    }

    if (this.skipVideoEnabled && this.isInvitationSection(section)) {
      this.ensureFrameSkipVideo(path)
    }
  }

  restoreSkipVideoPreference() {
    if (!this.hasSkipVideoTarget) return
    this.skipVideoTarget.checked = window.localStorage.getItem(SKIP_VIDEO_STORAGE_KEY) === "1"
  }

  toggleSkipVideo() {
    if (!this.hasSkipVideoTarget) return

    window.localStorage.setItem(SKIP_VIDEO_STORAGE_KEY, this.skipVideoTarget.checked ? "1" : "0")
    if (!this.isInvitationSection(this.sectionValue)) return
    this.reloadFrame()
  }

  updateSkipVideoControl(section) {
    if (!this.hasSkipVideoControlTarget) return
    this.skipVideoControlTarget.hidden = !this.isInvitationSection(section)
  }

  isInvitationSection(section) {
    return INVITATION_SECTIONS.has(section)
  }

  get skipVideoEnabled() {
    return this.hasSkipVideoTarget && this.skipVideoTarget.checked
  }

  ensureFrameSkipVideo(path) {
    if (this.ensuringSkipVideo) return

    try {
      const frameWindow = this.frameTarget.contentWindow
      if (!frameWindow) return

      const url = new URL(frameWindow.location.href)
      if (url.searchParams.get("skip_video") === "1") return

      this.ensuringSkipVideo = true
      url.searchParams.set("skip_video", "1")
      this.showFrameLoading()
      frameWindow.location.replace(url.pathname + url.search)
    } catch (_error) {
      this.ensuringSkipVideo = false
    }
  }

  framePathWithSkip(path) {
    const url = new URL(path, window.location.origin)
    if (this.skipVideoEnabled && this.isInvitationSection(this.sectionForPath(url.pathname))) {
      url.searchParams.set("skip_video", "1")
    } else {
      url.searchParams.delete("skip_video")
    }
    return url.pathname + url.search
  }

  sectionForPath(path) {
    const pages = this.hasPagesValue ? this.pagesValue : {}
    if (pages[path]) return pages[path]
    const match = Object.entries(pages).find(([prefix]) => prefix !== "/" && path.startsWith(`${prefix}/`))
    if (match) return match[1]
    if (path === "/") return "home"
    return null
  }

  syncAdminUrl(section) {
    if (!section || section === "look") return

    const urls = this.hasSectionUrlsValue ? this.sectionUrlsValue : {}
    const url = urls[section]
    if (!url) return

    this.sectionValue = section
    this.saveUrlValue = url

    const nextPath = new URL(url, window.location.origin).pathname
    if (window.location.pathname !== nextPath) {
      history.replaceState({ themeSection: section }, "", url)
    }
  }

  defaultPanelFor(section) {
    if (section === "look") return "look"
    if (section === "home") return "home_settings"
    return section
  }

  async saveTextField(field, value) {
    const body = this.fieldToFormData(field, value)
    if (!body) return

    this.syncFormField(field, value)
    await this.patchWedding(body, { reload: true, toast: "Saved" })
  }

  syncFormField(field, value) {
    const name = FIELD_INPUT_NAME[field]
    if (!name) return

    const form = this.contentFormForField(field)
    const input = form?.querySelector(`[name="${CSS.escape(name)}"]`)
      || form?.querySelector(`[name="${name}"]`)
    if (!input) return

    input.value = value
  }

  openSlotPicker(slotKey) {
    if (!this.hasSlotPickersTarget) return

    const picker = this.slotPickersTarget.querySelector(`[data-field-name="wedding[placements][${slotKey}][]"]`)
    if (!picker) {
      this.openDrawerFor(this.currentPanel, { mode: "page" })
      return
    }

    const openBtn = picker.querySelector("[data-action*='asset-picker#open']")
    if (openBtn) openBtn.click()
  }

  async saveSlotPicker() {
    if (!this.hasSlotPickersTarget) return

    const body = new FormData()
    this.slotPickersTarget.querySelectorAll("[data-asset-picker-target='picker']").forEach((picker) => {
      const fieldName = picker.dataset.fieldName
      body.append(fieldName, "")
      picker.querySelectorAll("[data-asset-picker-target='selected']").forEach((item) => {
        body.append(fieldName, item.dataset.assetId)
      })
    })

    this.mirrorPlacementPickers(this.slotPickersTarget, this.element)
    await this.patchWedding(body, { reload: true, toast: "Photo updated" })
  }

  // Keep duplicate placement pickers (hidden slot tray vs page forms) identical.
  mirrorPlacementPickers(sourceRoot, targetRoot) {
    if (!sourceRoot || !targetRoot) return

    sourceRoot.querySelectorAll("[data-asset-picker-target='picker']").forEach((source) => {
      const fieldName = source.dataset.fieldName
      if (!fieldName?.includes("[placements]")) return

      Array.from(targetRoot.querySelectorAll("[data-asset-picker-target='picker']"))
        .filter((target) => target !== source && target.dataset.fieldName === fieldName)
        .forEach((target) => this.copyPickerSelection(source, target))
    })
  }

  copyPickerSelection(source, target) {
    const selection = target.querySelector("[data-asset-picker-target='selection']")
    if (!selection) return

    const ids = Array.from(source.querySelectorAll("[data-asset-picker-target='selected']")).map((el) => ({
      id: el.dataset.assetId,
      thumb: el.querySelector("img")?.getAttribute("src") || ""
    }))

    selection.replaceChildren()
    ids.forEach(({ id, thumb }) => {
      const html = this.element.querySelector("[data-asset-picker-target='itemTemplate']")?.innerHTML
      if (!html) return
      selection.insertAdjacentHTML(
        "beforeend",
        html
          .split("__FIELD_NAME__").join(target.dataset.fieldName)
          .split("__ASSET_ID__").join(id)
          .split("__THUMB_URL__").join(thumb)
      )
    })
  }

  fieldToFormData(field, value) {
    const body = new FormData()
    const form = this.contentFormForField(field)

    if (field.startsWith("story.")) {
      const enabled = form?.querySelector("[name='wedding[story][enabled]']")
      if (enabled?.checked) body.append("wedding[story][enabled]", "1")
      const title = field === "story.title" ? value : form?.querySelector("[name='wedding[story][title]']")?.value
      const paragraphs = field === "story.paragraphs" ? value : form?.querySelector("[name='wedding[story][paragraphs_text]']")?.value
      const closing = field === "story.closing" ? value : form?.querySelector("[name='wedding[story][closing]']")?.value
      if (title != null) body.append("wedding[story][title]", title)
      if (paragraphs != null) body.append("wedding[story][paragraphs_text]", paragraphs)
      if (closing != null) body.append("wedding[story][closing]", closing)
      return body
    }

    const name = FIELD_INPUT_NAME[field]
    if (!name) return null
    body.append(name, value)
    return body
  }

  contentFormForField(field) {
    const section = FIELD_SECTION[field]
    if (!section) return this.activeContentForm

    const panel = this.defaultPanelFor(section)
    return this.panelTargets
      .find((element) => element.dataset.panel === panel)
      ?.querySelector("form")
  }

  get activeContentForm() {
    return this.panelTargets.find((panel) => !panel.hidden)?.querySelector("form")
  }

  async patchWedding(body, { reload, toast }) {
    this.setStatus("Saving…")

    const response = await fetch(this.saveUrlValue, {
      method: "PATCH",
      body,
      headers: {
        "X-CSRF-Token": this.csrfToken,
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest"
      },
      credentials: "same-origin"
    })

    if (!response.ok) {
      this.setStatus("Could not save")
      this.pushToast("Could not save changes", "error")
      return false
    }

    this.setStatus("Saved")
    if (toast) this.pushToast(toast, "success")
    if (reload) this.reloadFrame()
    return true
  }

  pushToast(message, kind) {
    if (!this.hasToastStackTarget) return

    const el = document.createElement("div")
    el.className = `admin-toast admin-toast--${kind === "error" ? "error" : "success"}`
    el.dataset.controller = "toast"
    el.dataset.toastDelayValue = "2500"
    el.setAttribute("role", kind === "error" ? "alert" : "status")
    el.innerHTML = `<p class="admin-toast__message"></p>
      <button type="button" class="admin-toast__dismiss" data-action="toast#dismiss" aria-label="Dismiss">&times;</button>`
    el.querySelector(".admin-toast__message").textContent = message
    this.toastStackTarget.appendChild(el)
  }

  async persist({ reload }) {
    if (!this.hasLookFormTarget) return

    const body = new FormData(this.lookFormTarget)
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

  reloadFrame() {
    const frame = this.frameTarget
    const frameWindow = frame.contentWindow
    if (!frameWindow) return

    const offset = frameWindow.scrollY || 0
    const next = this.framePathWithSkip(frameWindow.location.pathname + frameWindow.location.search)

    this.showFrameLoading()
    frame.addEventListener("load", () => {
      this.hideFrameLoading()
      frame.contentWindow?.scrollTo(0, offset)
    }, { once: true })

    if (`${frameWindow.location.pathname}${frameWindow.location.search}` === next) {
      frameWindow.location.reload()
    } else {
      frameWindow.location.assign(next)
    }
  }

  showFrameLoading() {
    if (this.hasFrameLoadingTarget) this.frameLoadingTarget.hidden = false
    this.frameStageTarget?.classList.add("is-loading")
  }

  hideFrameLoading() {
    if (this.hasFrameLoadingTarget) this.frameLoadingTarget.hidden = true
    this.frameStageTarget?.classList.remove("is-loading")
  }

  writeToken(token, value) {
    this.previewRoot?.style.setProperty(token, value)
  }

  syncPairedInputs(source) {
    const role = source.dataset.themeRole
    if (!role) return

    this.colorInputs
      .filter((input) => input.dataset.themeRole === role && input !== source)
      .forEach((input) => { input.value = source.value })
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

  get formTarget() {
    return this.hasLookFormTarget ? this.lookFormTarget : null
  }

  get hasFormTarget() {
    return this.hasLookFormTarget
  }

  get colorInputs() {
    if (!this.hasLookFormTarget) return []
    return Array.from(this.lookFormTarget.querySelectorAll("[data-theme-role]"))
  }

  get fontSelect() {
    return this.lookFormTarget?.querySelector("[data-theme-font-select]")
  }

  get previewRoot() {
    return this.frameTarget.contentDocument?.documentElement
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
