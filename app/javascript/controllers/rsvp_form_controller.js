import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radioCard", "conditionalFields"]
  static values = { guestIds: Array }

  connect() {
    this.initializeRadioCards()
    this.initializeConditionalFields()
  }

  initializeRadioCards() {
    this.radioCardTargets.forEach(card => {
      const radio = card.previousElementSibling
      if (radio && radio.checked) {
        this.styleCardAsSelected(card)
      }
    })
  }

  initializeConditionalFields() {
    this.guestIdsValue.forEach(guestId => {
      const acceptedRadio = document.getElementById(`guest_${guestId}_accepted`)
      if (acceptedRadio && acceptedRadio.checked) {
        const fields = document.getElementById(`accepted_fields_${guestId}`)
        if (fields) {
          fields.classList.remove("hidden")
        }
      }
    })
  }

  selectRadio(event) {
    const card = event.currentTarget
    const radio = card.previousElementSibling
    const name = radio.name

    document.querySelectorAll(`input[name="${name}"]`).forEach(r => {
      const siblingCard = r.nextElementSibling
      if (siblingCard && siblingCard.hasAttribute("data-rsvp-form-target")) {
        this.styleCardAsUnselected(siblingCard)
      }
    })

    this.styleCardAsSelected(card)
    this.toggleConditionalFields(radio)
  }

  // The selected appearance lives in `.rsvp-radio-card.selected` so it follows the
  // wedding's theme colours rather than being pinned to one palette here.
  styleCardAsSelected(card) {
    card.classList.add("selected")
  }

  styleCardAsUnselected(card) {
    card.classList.remove("selected")
  }

  toggleConditionalFields(radio) {
    const match = radio.id.match(/guest_(\d+)_(accepted|declined)/)
    if (!match) return

    const guestId = match[1]
    const status = match[2]
    const fields = document.getElementById(`accepted_fields_${guestId}`)

    if (!fields) return

    if (status === "accepted") {
      fields.classList.remove("hidden")
      fields.classList.add("animate-fade-in-up")
    } else {
      fields.classList.add("hidden")
      fields.classList.remove("animate-fade-in-up")
    }
  }
}
