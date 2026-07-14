import { Controller } from "@hotwired/stimulus"

// Generic add/remove for nested form rows using a <template> target.
export default class extends Controller {
  static targets = ["container", "template", "item"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, String(Date.now()))
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const item = event.currentTarget.closest("[data-nested-form-target='item']")
    if (item) item.remove()
  }
}
