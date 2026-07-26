import { Controller } from "@hotwired/stimulus"

// Saves library alt text on its own, so the surrounding wedding form is untouched.
export default class extends Controller {
  async updateAlt(event) {
    const input = event.currentTarget
    const url = input.dataset.url
    if (!url) return

    input.classList.remove("is-invalid")

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          "Content-Type": "application/json",
          Accept: "application/json"
        },
        body: JSON.stringify({ wedding_asset: { alt: input.value } }),
        credentials: "same-origin"
      })

      if (!response.ok) throw new Error("Save failed")
    } catch (_error) {
      input.classList.add("is-invalid")
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
