import { Controller } from "@hotwired/stimulus"

const DEFAULT_DEBOUNCE_MS = 450

// Autosaves a form via PATCH with JSON Accept. Used by Wedding settings and
// similar admin panels — Theme look & feel stays draft + explicit Save.
export default class extends Controller {
  static values = {
    debounce: { type: Number, default: DEFAULT_DEBOUNCE_MS },
    toast: { type: String, default: "Saved" }
  }

  connect() {
    this.timer = null
    this.saving = false
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  queue(event) {
    if (event?.target?.closest("[data-autosave-ignore]")) return

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.save(), this.debounceValue)
  }

  async save(event) {
    event?.preventDefault()
    clearTimeout(this.timer)

    if (this.saving) return
    this.saving = true

    try {
      const response = await fetch(this.element.action, {
        method: "PATCH",
        body: new FormData(this.element),
        headers: {
          "X-CSRF-Token": this.csrfToken,
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin"
      })

      if (!response.ok) {
        this.pushToast("Could not save changes", "error")
        return
      }

      this.pushToast(this.toastValue, "success")
    } catch (_error) {
      this.pushToast("Could not save changes", "error")
    } finally {
      this.saving = false
    }
  }

  pushToast(message, kind) {
    let stack = document.querySelector(".admin-toast-stack")
    if (!stack) {
      stack = document.createElement("div")
      stack.className = "admin-toast-stack print:hidden"
      stack.setAttribute("aria-live", "polite")
      document.body.appendChild(stack)
    }

    const el = document.createElement("div")
    el.className = `admin-toast admin-toast--${kind === "error" ? "error" : "success"}`
    el.dataset.controller = "toast"
    el.dataset.toastDelayValue = kind === "error" ? "7000" : "2500"
    el.setAttribute("role", kind === "error" ? "alert" : "status")
    el.innerHTML = `<p class="admin-toast__message"></p>
      <button type="button" class="admin-toast__dismiss" data-action="toast#dismiss" aria-label="Dismiss">&times;</button>`
    el.querySelector(".admin-toast__message").textContent = message
    stack.appendChild(el)
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
