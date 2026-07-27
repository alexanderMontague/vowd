import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "submit", "master"]
  static values = {
    checkboxSelector: { type: String, default: 'input[type="checkbox"]' },
    requireSelection: { type: Boolean, default: false }
  }

  connect() {
    this.refreshBound = () => this.refresh()
    this.syncFromMasterBound = () => this.syncFromMaster()
    this.onChangeBound = (event) => {
      if (event.target.matches?.(this.checkboxSelectorValue)) this.refresh()
    }

    // Delegated so checkboxes added via Turbo streams stay wired.
    this.element.addEventListener("change", this.onChangeBound)
    document.addEventListener("turbo:after-stream-render", this.refreshBound)

    if (this.hasMasterTarget) {
      this.masterTarget.addEventListener("change", this.syncFromMasterBound)
    }
    this.refresh()
  }

  disconnect() {
    this.element.removeEventListener("change", this.onChangeBound)
    document.removeEventListener("turbo:after-stream-render", this.refreshBound)
    if (this.hasMasterTarget) {
      this.masterTarget.removeEventListener("change", this.syncFromMasterBound)
    }
  }

  refresh() {
    const boxes = this.checkboxElements()
    const checkedCount = boxes.filter((cb) => cb.checked).length

    if (this.hasCountTarget) {
      this.countTarget.textContent = String(checkedCount)
    }
    if (this.hasSubmitTarget && this.requireSelectionValue) {
      this.submitTarget.disabled = checkedCount === 0
    }
    if (this.hasMasterTarget) {
      const total = boxes.length
      this.masterTarget.checked = total > 0 && checkedCount === total
      this.masterTarget.indeterminate = checkedCount > 0 && checkedCount < total
    }
  }

  syncFromMaster() {
    const checked = this.masterTarget.checked
    this.element.querySelectorAll(this.checkboxSelectorValue).forEach((cb) => {
      cb.checked = checked
    })
    this.refresh()
  }

  checkboxElements() {
    return [...this.element.querySelectorAll(this.checkboxSelectorValue)]
  }
}
