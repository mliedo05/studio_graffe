import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step1", "step2", "step3", "form",
                    "serviceIdField", "stylistIdField",
                    "selectedServiceName", "selectedStylistName",
                    "progress"]

  connect() {
    this.currentStep = 1
    this.showStep(1)
  }

  selectService(event) {
    const card = event.currentTarget
    // deselect all
    this.element.querySelectorAll(".service-card").forEach(c => {
      c.classList.remove("border-primary", "bg-surface-container-low", "ring-2", "ring-primary/20")
    })
    // select this
    card.classList.add("border-primary", "bg-surface-container-low", "ring-2", "ring-primary/20")

    if (this.hasServiceIdFieldTarget) {
      this.serviceIdFieldTarget.value = card.dataset.serviceId
    }
    if (this.hasSelectedServiceNameTarget) {
      this.selectedServiceNameTarget.textContent = card.dataset.serviceName
    }

    // auto-advance after brief delay
    setTimeout(() => this.nextStep(), 400)
  }

  selectStylist(event) {
    const card = event.currentTarget
    this.element.querySelectorAll(".stylist-card").forEach(c => {
      c.classList.remove("border-primary", "ring-2", "ring-primary/20")
    })
    card.classList.add("border-primary", "ring-2", "ring-primary/20")

    if (this.hasStylistIdFieldTarget) {
      this.stylistIdFieldTarget.value = card.dataset.stylistId
    }
    if (this.hasSelectedStylistNameTarget) {
      this.selectedStylistNameTarget.textContent = card.dataset.stylistName
    }

    setTimeout(() => this.nextStep(), 400)
  }

  nextStep() {
    if (this.currentStep < 3) {
      this.currentStep++
      this.showStep(this.currentStep)
    }
  }

  prevStep() {
    if (this.currentStep > 1) {
      this.currentStep--
      this.showStep(this.currentStep)
    }
  }

  showStep(step) {
    // hide all steps
    ;[this.step1Targets, this.step2Targets, this.step3Targets].flat().forEach(el => {
      el.classList.add("hidden")
    })

    // show current
    const targets = this[`step${step}Targets`]
    targets.forEach(el => el.classList.remove("hidden"))

    // update progress indicators
    for (let i = 1; i <= 3; i++) {
      const indicator = this.element.querySelector(`.step-indicator-${i}`)
      if (!indicator) continue
      if (i < step) {
        indicator.className = indicator.className.replace(/bg-\S+|border-\S+|text-\S+/g, "").trim()
        indicator.classList.add("bg-tertiary-fixed", "border-tertiary-fixed", "text-on-tertiary-fixed")
      } else if (i === step) {
        indicator.className = indicator.className.replace(/bg-\S+|border-\S+|text-\S+/g, "").trim()
        indicator.classList.add("bg-primary", "border-primary", "text-on-primary", "ring-4", "ring-tertiary-fixed/30")
      } else {
        indicator.className = indicator.className.replace(/bg-\S+|border-\S+|text-\S+/g, "").trim()
        indicator.classList.add("bg-secondary-fixed", "border-outline-variant", "text-on-secondary-fixed")
      }
    }
  }
}
