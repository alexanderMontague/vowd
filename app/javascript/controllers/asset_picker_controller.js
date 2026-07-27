import { Controller } from "@hotwired/stimulus"

const FIELD_NAME_TOKEN = "__FIELD_NAME__"
const ASSET_ID_TOKEN = "__ASSET_ID__"
const THUMB_URL_TOKEN = "__THUMB_URL__"
const UNLIMITED = 0
const LABEL_SEPARATOR = " · "
const UNTITLED_SECTION = "Untitled section"

// One shared library dialog serving every picker in the panel. A picker owns the
// hidden inputs for its slot or section; the dialog only reads and writes them.
export default class extends Controller {
  static targets = ["dialog", "option", "picker", "selection", "selected", "hint", "itemTemplate", "usage"]
  // Saved placements across every page. Live pickers on this panel override their
  // own labels so badges stay truthful before save.
  static values = { usage: Object }

  connect() {
    this.activePicker = null
    this.refreshUsage()
  }

  open(event) {
    this.activePicker = event.currentTarget.closest("[data-asset-picker-target='picker']")
    if (!this.activePicker || !this.hasDialogTarget) return

    this.setHint(this.limitHint())
    this.syncOptions()
    this.dialogTarget.showModal()
  }

  close() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  toggle(event) {
    if (!this.activePicker) return

    const option = event.currentTarget
    const assetId = option.dataset.assetId
    const chosen = this.selectedItem(this.activePicker, assetId)

    if (chosen) {
      chosen.remove()
      this.setHint(this.limitHint())
      this.syncOptions()
      this.refreshUsage()
      return
    }

    const max = this.limit()
    const selection = this.selection()

    if (max === 1) {
      selection.replaceChildren()
    } else if (max !== UNLIMITED && selection.children.length >= max) {
      this.setHint(`You can choose up to ${max}.`)
      return
    }

    selection.insertAdjacentHTML("beforeend", this.itemHtml(assetId, option.dataset.thumbUrl))
    this.setHint(this.limitHint())
    this.syncOptions()
    this.refreshUsage()
  }

  deselect(event) {
    const item = event.currentTarget.closest("[data-asset-picker-target='selected']")
    if (!item) return

    const picker = item.closest("[data-asset-picker-target='picker']")
    item.remove()

    if (picker === this.activePicker && this.hasDialogTarget && this.dialogTarget.open) this.syncOptions()

    this.refreshUsage()
  }

  // Badges answer "where does this photo appear?" across every page. Live picker
  // state on this panel replaces the saved labels for those same placements.
  refreshUsage() {
    const labels = this.usageLabels()

    this.usageTargets.forEach((element) => {
      this.renderBadges(element, labels.get(element.dataset.assetId) || [])
    })
  }

  usageLabels() {
    const labels = this.baselineUsage()
    const liveLabels = new Set(this.pickerTargets.map((picker) => this.pickerLabel(picker)))

    for (const [assetId, placed] of labels) {
      labels.set(assetId, placed.filter((label) => !liveLabels.has(label)))
    }

    this.pickerTargets.forEach((picker) => {
      const label = this.pickerLabel(picker)

      picker.querySelectorAll("[data-asset-picker-target='selected']").forEach(({ dataset }) => {
        const placed = labels.get(dataset.assetId) || []
        if (!placed.includes(label)) placed.push(label)
        labels.set(dataset.assetId, placed)
      })
    })

    return labels
  }

  baselineUsage() {
    const map = new Map()
    const raw = this.hasUsageValue ? this.usageValue : {}

    Object.entries(raw).forEach(([assetId, placed]) => {
      map.set(assetId, [...placed])
    })

    return map
  }

  // Slots carry a fixed label; a section is named by its title field as it is typed.
  pickerLabel(picker) {
    const { usageLabel, usagePrefix } = picker.dataset
    const name = usageLabel || this.sectionTitle(picker) || UNTITLED_SECTION

    return [usagePrefix, name].filter(Boolean).join(LABEL_SEPARATOR)
  }

  sectionTitle(picker) {
    return picker.closest("[data-usage-scope]")?.querySelector("[data-usage-title]")?.value.trim()
  }

  renderBadges(element, labels) {
    element.replaceChildren(...labels.map((label) => this.badge(label)))
    element.title = labels.join(", ")
  }

  badge(label) {
    const badge = document.createElement("span")
    badge.className = "admin-usage-badge"
    badge.textContent = label

    return badge
  }

  syncOptions() {
    this.optionTargets.forEach((option) => {
      const selected = Boolean(this.selectedItem(this.activePicker, option.dataset.assetId))
      option.setAttribute("aria-pressed", selected ? "true" : "false")
    })
  }

  itemHtml(assetId, thumbUrl) {
    return this.itemTemplateTarget.innerHTML
      .split(FIELD_NAME_TOKEN).join(this.activePicker.dataset.fieldName)
      .split(ASSET_ID_TOKEN).join(assetId)
      .split(THUMB_URL_TOKEN).join(thumbUrl)
  }

  selectedItem(picker, assetId) {
    if (!picker) return null

    return picker.querySelector(`[data-asset-picker-target='selected'][data-asset-id='${assetId}']`)
  }

  selection() {
    return this.activePicker.querySelector("[data-asset-picker-target='selection']")
  }

  limit() {
    return Number(this.activePicker.dataset.max || UNLIMITED)
  }

  limitHint() {
    const max = this.limit()
    if (max === 1) return "Choose one photo."
    if (max === UNLIMITED) return "Choose as many as you like."

    return `Choose up to ${max} photos.`
  }

  setHint(message) {
    if (this.hasHintTarget) this.hintTarget.textContent = message
  }
}
