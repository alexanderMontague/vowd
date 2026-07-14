import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: { type: String, default: "core" } }

  connect() {
    this.show(this.activeValue)
  }

  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.dataset.tabsIdParam)
  }

  show(id) {
    this.activeValue = id

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.tabsIdParam === id
      tab.classList.toggle("admin-tab-active", active)
      tab.setAttribute("aria-selected", active ? "true" : "false")
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tabsIdParam !== id
    })
  }
}
