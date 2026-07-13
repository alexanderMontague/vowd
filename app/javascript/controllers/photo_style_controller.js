import { Controller } from "@hotwired/stimulus";

// Switches the active display treatment (original / retro / bw) for a group of
// photos. The active style is written to `data-photo-style` on the controller
// element so CSS can scope which filter layers are visible; per-photo variation
// is handled independently by the retro-photo controller.
export default class extends Controller {
  static values = { current: String };
  static targets = ["option"];

  connect() {
    this.render();
  }

  currentValueChanged() {
    this.render();
  }

  select({ params }) {
    if (params.option) this.currentValue = params.option;
  }

  render() {
    this.element.dataset.photoStyle = this.currentValue;
    this.optionTargets.forEach((option) => {
      const isActive = option.dataset.styleOption === this.currentValue;
      option.classList.toggle("is-active", isActive);
      option.setAttribute("aria-pressed", String(isActive));
    });
  }
}
