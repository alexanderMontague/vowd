import { Controller } from "@hotwired/stimulus"

// Generic add/remove for nested form rows using a <template> target.
// Optional drag-and-drop reorder + a sticky Add control that stays visible
// while the section's own toolbar is scrolled out of view.
export default class extends Controller {
  static targets = ["container", "template", "item", "toolbar", "addButton", "stickyAdd"]
  static values = {
    // Optional placeholder so nested templates can use different tokens
    // (e.g. NEW_SECTION_INDEX vs NEW_IMAGE_INDEX) without colliding.
    placeholder: { type: String, default: "NEW_INDEX" },
    sortable: { type: Boolean, default: false },
    stickyAdd: { type: Boolean, default: false }
  }

  connect() {
    this.dragItem = null
    if (this.sortableValue) this.#bindSortable()
    if (this.stickyAddValue) this.#bindStickyAdd()
  }

  disconnect() {
    this.#teardownSortable()
    this.#teardownStickyAdd()
  }

  add(event) {
    event.preventDefault()
    const token = this.placeholderValue
    const html = this.templateTarget.innerHTML.split(token).join(String(Date.now()))
    this.containerTarget.insertAdjacentHTML("beforeend", html)
    if (this.sortableValue) this.#refreshItemBindings()
    this.#reindex()
    this.dispatch("changed")
  }

  remove(event) {
    event.preventDefault()
    const item = event.currentTarget.closest("[data-nested-form-target='item']")
    if (!item) return

    item.remove()
    this.#reindex()
    this.dispatch("removed")
    this.dispatch("changed")
  }

  #bindSortable() {
    this.onDragStart = this.#onDragStart.bind(this)
    this.onDragOver = this.#onDragOver.bind(this)
    this.onDrop = this.#onDrop.bind(this)
    this.onDragEnd = this.#onDragEnd.bind(this)
    this.containerTarget.addEventListener("dragstart", this.onDragStart)
    this.containerTarget.addEventListener("dragover", this.onDragOver)
    this.containerTarget.addEventListener("drop", this.onDrop)
    this.containerTarget.addEventListener("dragend", this.onDragEnd)
    this.#refreshItemBindings()
  }

  #teardownSortable() {
    if (!this.onDragStart) return
    this.containerTarget.removeEventListener("dragstart", this.onDragStart)
    this.containerTarget.removeEventListener("dragover", this.onDragOver)
    this.containerTarget.removeEventListener("drop", this.onDrop)
    this.containerTarget.removeEventListener("dragend", this.onDragEnd)
  }

  #refreshItemBindings() {
    this.itemTargets.forEach((item) => {
      item.removeAttribute("draggable")
      const handle = item.querySelector("[data-nested-form-handle]")
      if (handle) handle.setAttribute("draggable", "true")
    })
  }

  #onDragStart(event) {
    const handle = event.target.closest("[data-nested-form-handle]")
    if (!handle) {
      event.preventDefault()
      return
    }

    const item = handle.closest("[data-nested-form-target='item']")
    if (!item || !this.containerTarget.contains(item)) return

    this.dragItem = item
    item.classList.add("is-dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "nested-form-item")
    try {
      event.dataTransfer.setDragImage(item, 16, 16)
    } catch (_) {
      // Some browsers reject setDragImage outside a trusted drag gesture path.
    }
  }

  #onDragOver(event) {
    if (!this.dragItem) return
    event.preventDefault()
    const over = event.target.closest("[data-nested-form-target='item']")
    if (!over || over === this.dragItem || !this.containerTarget.contains(over)) return

    const rect = over.getBoundingClientRect()
    const before = event.clientY < rect.top + rect.height / 2
    this.containerTarget.insertBefore(this.dragItem, before ? over : over.nextSibling)
  }

  #onDrop(event) {
    event.preventDefault()
  }

  #onDragEnd() {
    if (this.dragItem) this.dragItem.classList.remove("is-dragging")
    this.dragItem = null
    this.#reindex()
    this.dispatch("changed")
  }

  // Rewrite collection indices in field names so order matches DOM order.
  #reindex() {
    this.itemTargets.forEach((item, index) => {
      item.querySelectorAll("[name]").forEach((input) => {
        input.name = input.name.replace(
          /\[(bridesmaids|groomsmen|questions|sections)\]\[\d+\]/,
          `[$1][${index}]`
        )
      })
    })
  }

  #bindStickyAdd() {
    if (!this.hasToolbarTarget || !this.hasStickyAddTarget) return

    this.scrollRoot = this.element.closest(".theme-editor-drawer__body, .admin-main, .overflow-y-auto") || null
    this.onScroll = this.#updateStickyAdd.bind(this)
    this.intersection = new IntersectionObserver(
      () => this.#updateStickyAdd(),
      { root: this.scrollRoot, threshold: 0, rootMargin: "0px" }
    )
    this.intersection.observe(this.toolbarTarget)
    if (this.scrollRoot) this.scrollRoot.addEventListener("scroll", this.onScroll, { passive: true })
    this.#updateStickyAdd()
  }

  #teardownStickyAdd() {
    this.intersection?.disconnect()
    if (this.scrollRoot && this.onScroll) {
      this.scrollRoot.removeEventListener("scroll", this.onScroll)
    }
  }

  #updateStickyAdd() {
    if (!this.hasToolbarTarget || !this.hasStickyAddTarget) return

    const toolbarVisible = this.#isInScrollView(this.toolbarTarget)
    const sectionStillInView = this.#isInScrollView(this.element, { partial: true })
    const show = !toolbarVisible && sectionStillInView
    this.stickyAddTarget.hidden = !show
  }

  #isInScrollView(element, { partial = false } = {}) {
    const root = this.scrollRoot
    const rect = element.getBoundingClientRect()
    if (!root) {
      return partial
        ? rect.bottom > 0 && rect.top < window.innerHeight
        : rect.top >= 0 && rect.bottom <= window.innerHeight
    }

    const rootRect = root.getBoundingClientRect()
    if (partial) {
      return rect.bottom > rootRect.top + 8 && rect.top < rootRect.bottom - 8
    }
    return rect.top >= rootRect.top && rect.bottom <= rootRect.bottom
  }
}
