import { Controller } from "@hotwired/stimulus"

// Generic add/remove for nested form rows using a <template> target.
export default class extends Controller {
  static targets = ["container", "template", "item"]
  static values = {
    // Optional placeholder so nested templates can use different tokens
    // (e.g. NEW_SECTION_INDEX vs NEW_IMAGE_INDEX) without colliding.
    placeholder: { type: String, default: "NEW_INDEX" }
  }

  add(event) {
    event.preventDefault()
    const token = this.placeholderValue
    const html = this.templateTarget.innerHTML.split(token).join(String(Date.now()))
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const item = event.currentTarget.closest("[data-nested-form-target='item']")
    if (!item) return

    item.remove()
    this.dispatch("removed")
  }
}
