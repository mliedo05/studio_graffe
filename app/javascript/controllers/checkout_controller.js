import { Controller } from "@hotwired/stimulus"

const REGIONS = {
  "Arica y Parinacota": ["Arica", "Camarones", "General Lagos", "Putre"],
  "Tarapacá": ["Alto Hospicio", "Camiña", "Colchane", "Huara", "Iquique", "Pica", "Pozo Almonte"],
  "Antofagasta": ["Antofagasta", "Calama", "María Elena", "Mejillones", "Ollagüe", "San Pedro de Atacama", "Sierra Gorda", "Taltal", "Tocopilla"],
  "Atacama": ["Alto del Carmen", "Caldera", "Chañaral", "Copiapó", "Diego de Almagro", "Freirina", "Huasco", "Tierra Amarilla", "Vallenar"],
  "Coquimbo": ["Andacollo", "Canela", "Combarbalá", "Coquimbo", "Illapel", "La Higuera", "La Serena", "Los Vilos", "Monte Patria", "Ovalle", "Paiguano", "Punitaqui", "Río Hurtado", "Salamanca", "Vicuña"],
  "Valparaíso": ["Algarrobo", "Cabildo", "Calera", "Calle Larga", "Cartagena", "Casablanca", "Catemu", "Concón", "El Quisco", "El Tabo", "Hijuelas", "Isla de Pascua", "Juan Fernández", "La Cruz", "La Ligua", "Limache", "Llaillay", "Los Andes", "Nogales", "Olmué", "Panquehue", "Papudo", "Petorca", "Puchuncaví", "Putaendo", "Quillota", "Quilpué", "Quintero", "Rinconada", "San Antonio", "San Esteban", "San Felipe", "Santa María", "Santo Domingo", "Valparaíso", "Villa Alemana", "Viña del Mar", "Zapallar"],
  "Metropolitana": ["Alhué", "Buin", "Calera de Tango", "Cerrillos", "Cerro Navia", "Colina", "Conchalí", "Curacaví", "El Bosque", "El Monte", "Estación Central", "Huechuraba", "Independencia", "Isla de Maipo", "La Cisterna", "La Florida", "La Granja", "La Pintana", "La Reina", "Lampa", "Las Condes", "Lo Barnechea", "Lo Espejo", "Lo Prado", "Macul", "Maipú", "Melipilla", "Padre Hurtado", "Paine", "Pedro Aguirre Cerda", "Peñaflor", "Peñalolén", "Pirque", "Providencia", "Pudahuel", "Puente Alto", "Quilicura", "Quinta Normal", "Recoleta", "Renca", "San Bernardo", "San Joaquín", "San José de Maipo", "San Miguel", "San Pedro", "San Ramón", "Santiago", "Talagante", "Tiltil", "Vitacura", "Ñuñoa"],
  "O'Higgins": ["Chépica", "Chimbarongo", "Codegua", "Coinco", "Coltauco", "Doñihue", "Graneros", "La Estrella", "Las Cabras", "Litueche", "Lolol", "Machalí", "Malloa", "Marchihue", "Mostazal", "Nancagua", "Navidad", "Olivar", "Palmilla", "Paredones", "Peralillo", "Peumo", "Pichidegua", "Pichilemu", "Placilla", "Pumanque", "Quinta de Tilcoco", "Rancagua", "Rengo", "Requínoa", "San Fernando", "San Vicente", "Santa Cruz"],
  "Maule": ["Cauquenes", "Chanco", "Colbún", "Constitución", "Curepto", "Curicó", "Empedrado", "Hualañé", "Licantén", "Linares", "Longaví", "Maule", "Molina", "Parral", "Pelarco", "Pelluhue", "Pencahue", "Rauco", "Retiro", "Río Claro", "Romeral", "Sagrada Familia", "San Clemente", "San Javier", "San Rafael", "Talca", "Teno", "Vichuquén", "Villa Alegre", "Yerbas Buenas"],
  "Ñuble": ["Bulnes", "Chillán", "Chillán Viejo", "Cobquecura", "Coelemu", "Coihueco", "El Carmen", "Ninhue", "Ñiquén", "Pemuco", "Pinto", "Portezuelo", "Quillón", "Quirihue", "Ránquil", "San Carlos", "San Fabián", "San Ignacio", "San Nicolás", "Treguaco", "Yungay"],
  "Biobío": ["Alto Biobío", "Antuco", "Arauco", "Cañete", "Concepción", "Contulmo", "Coronel", "Curanilahue", "Florida", "Hualpén", "Hualqui", "Laja", "Lebu", "Los Álamos", "Los Ángeles", "Lota", "Mulchén", "Nacimiento", "Negrete", "Penco", "Quilaco", "Quilleco", "San Pedro de la Paz", "San Rosendo", "Santa Bárbara", "Santa Juana", "Talcahuano", "Tirúa", "Tomé", "Tucapel", "Yumbel"],
  "La Araucanía": ["Angol", "Carahue", "Cholchol", "Collipulli", "Cunco", "Curacautín", "Curarrehue", "Ercilla", "Freire", "Galvarino", "Gorbea", "Lautaro", "Loncoche", "Lonquimay", "Los Sauces", "Lumaco", "Melipeuco", "Nueva Imperial", "Padre las Casas", "Perquenco", "Pitrufquén", "Pucón", "Purén", "Renaico", "Saavedra", "Temuco", "Teodoro Schmidt", "Toltén", "Traiguén", "Victoria", "Vilcún", "Villarrica"],
  "Los Ríos": ["Corral", "Futrono", "La Unión", "Lago Ranco", "Lanco", "Los Lagos", "Máfil", "Mariquina", "Paillaco", "Panguipulli", "Río Bueno", "Valdivia"],
  "Los Lagos": ["Ancud", "Calbuco", "Castro", "Chaitén", "Chonchi", "Cochamó", "Curaco de Vélez", "Dalcahue", "Fresia", "Frutillar", "Futaleufú", "Hualaihué", "Llanquihue", "Los Muermos", "Maullín", "Osorno", "Palena", "Puerto Montt", "Puerto Octay", "Puerto Varas", "Puqueldón", "Purranque", "Puyehue", "Queilén", "Quemchi", "Quínchao", "Río Negro", "San Juan de la Costa", "San Pablo"],
  "Aysén": ["Aysén", "Chile Chico", "Cisnes", "Cochrane", "Coyhaique", "Guaitecas", "Lago Verde", "O'Higgins", "Río Ibáñez", "Tortel"],
  "Magallanes": ["Antártica", "Cabo de Hornos", "Laguna Blanca", "Natales", "Punta Arenas", "Río Verde", "San Gregorio", "Timaukel", "Torres del Paine"]
}

export default class extends Controller {
  static targets = [
    // Steps
    "step", "stepIndicator", "errorBanner",
    // Billing
    "documentNumber", "documentSelect",
    // Shipping
    "regionSelect", "comunaSelect", "shippingSection", "apartmentField", "apartmentWrapper",
    "addressForm",
    // Summary
    "summaryFirstName", "summaryLastName", "summaryDocument", "summaryEmail", "summaryPhone",
    "summaryShipping", "summaryAddress", "shippingCard"
  ]

  static values = { current: { type: Number, default: 0 } }

  connect() {
    this.showStep(this.currentValue)

    // Populate comunas if region already set (on back navigation)
    if (this.hasRegionSelectTarget && this.regionSelectTarget.value) {
      this.populateComunas(this.regionSelectTarget.value, this.comunaSelectTarget?.dataset.selected)
    }
  }

  // ── Step navigation ──────────────────────────────────────

  next() {
    if (!this.validateCurrentStep()) return
    // Hide error banner of current step before advancing
    const banner = this.errorBannerTargets[this.currentValue]
    if (banner) banner.classList.add("hidden")
    if (this.currentValue < this.stepTargets.length - 1) {
      this.updateSummary()
      this.currentValue++
      this.showStep(this.currentValue)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  back() {
    if (this.currentValue > 0) {
      this.currentValue--
      this.showStep(this.currentValue)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  goToStep(event) {
    const target = parseInt(event.currentTarget.dataset.step)
    // Only allow going back to completed steps
    if (target < this.currentValue) {
      this.currentValue = target
      this.showStep(this.currentValue)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  showStep(index) {
    this.stepTargets.forEach((step, i) => {
      step.classList.toggle("hidden", i !== index)
    })
    this.updateIndicators(index)
  }

  updateIndicators(activeIndex) {
    this.stepIndicatorTargets.forEach((el, i) => {
      el.dataset.state = i < activeIndex ? "done" : i === activeIndex ? "active" : "pending"
    })
  }

  // ── Validation ───────────────────────────────────────────

  validateCurrentStep() {
    const step        = this.stepTargets[this.currentValue]
    const banner      = this.errorBannerTargets[this.currentValue]
    let invalidFields = []

    // Mark a field wrapper as invalid
    const markInvalid = (field) => {
      const wrapper = field.closest(".border-b")
      if (wrapper) {
        wrapper.classList.add("border-red-400")
        wrapper.classList.remove("border-stone-300")

        // Add error hint if not already there
        if (!wrapper.querySelector(".field-error-msg")) {
          const msg = document.createElement("p")
          msg.className = "field-error-msg text-[10px] text-red-500 mt-1"
          msg.textContent = "Este campo es obligatorio"
          wrapper.appendChild(msg)
        }

        // Remove error when user fills the field
        const clear = () => {
          if (field.value.trim()) {
            wrapper.classList.remove("border-red-400")
            wrapper.classList.add("border-stone-300")
            wrapper.querySelector(".field-error-msg")?.remove()
          }
        }
        field.addEventListener("input",  clear, { once: true })
        field.addEventListener("change", clear, { once: true })
      } else {
        // Fallback for fields without wrapper (e.g. phone number input)
        field.classList.add("border-b", "border-red-400")
        field.addEventListener("input", () => field.classList.remove("border-red-400"), { once: true })
      }
      invalidFields.push(field)
    }

    // Validate all [required] fields in this step
    step.querySelectorAll("[required]").forEach(field => {
      if (!field.value.trim()) markInvalid(field)
    })

    // Step 2: extra address fields when delivery selected
    if (this.currentValue === 1) {
      const isDelivery = step.querySelector("[value='delivery']")?.checked
      if (isDelivery) {
        const names = ["shipping_recipient_name", "shipping_region", "shipping_comuna",
                       "shipping_city", "shipping_street", "shipping_street_number"]
        names.forEach(name => {
          const el = step.querySelector(`[name='order[${name}]']`)
          if (el && !el.value.trim()) markInvalid(el)
        })
        // Phone number field (custom component — check the number input)
        const phoneNum = step.querySelector("[name='order[shipping_phone_number]']")
        if (phoneNum && !phoneNum.value.trim()) markInvalid(phoneNum)
      }
    }

    const valid = invalidFields.length === 0

    // Show / hide banner
    if (banner) {
      banner.classList.toggle("hidden", valid)
      if (!valid) {
        banner.scrollIntoView({ behavior: "smooth", block: "nearest" })
      }
    }

    // Scroll to first invalid field if no banner
    if (!valid && !banner) {
      invalidFields[0]?.scrollIntoView({ behavior: "smooth", block: "center" })
    }

    return valid
  }

  // ── Summary panel (step 3) ───────────────────────────────

  updateSummary() {
    const get = (name) => this.element.querySelector(`[name='order[${name}]']`)?.value || ""
    const docType = { rut: "RUT", passport: "Pasaporte", dni: "DNI" }

    if (this.hasSummaryFirstNameTarget) {
      this.summaryFirstNameTarget.textContent = `${get("billing_first_name")} ${get("billing_last_name")}`
      this.summaryDocumentTarget.textContent   = `${docType[get("billing_document_type")] || ""} ${get("billing_document_number")}`
      this.summaryEmailTarget.textContent      = get("billing_email")
      const prefix = this.element.querySelector("[name='order[billing_phone_prefix]']")?.value || "+56"
      const number = this.element.querySelector("[name='order[billing_phone_number]']")?.value || get("billing_phone")
      this.summaryPhoneTarget.textContent = number ? `${prefix} ${number}` : get("billing_phone") || "—"
    }

    if (this.hasSummaryShippingTarget) {
      const isDelivery = this.element.querySelector("[value='delivery']")?.checked
      this.summaryShippingTarget.textContent = isDelivery ? "Delivery a domicilio" : "Retiro en tienda"

      // Show/hide shipping summary card
      if (this.hasShippingCardTarget) {
        this.shippingCardTarget.classList.toggle("hidden", !isDelivery)
      }

      if (this.hasSummaryAddressTarget) {
        if (isDelivery) {
          const parts = [get("shipping_street"), get("shipping_street_number"), get("shipping_apartment"), get("shipping_comuna"), get("shipping_region")].filter(Boolean)
          this.summaryAddressTarget.textContent = parts.join(", ")
        } else {
          this.summaryAddressTarget.textContent = ""
        }
      }
    }
  }

  // ── Fill / clear saved address ────────────────────────────

  fillAddress(event) {
    const d = event.currentTarget.dataset
    const set = (name, val) => {
      const el = this.element.querySelector(`[name='order[${name}]']`)
      if (el) el.value = val || ""
    }
    set("shipping_recipient_name", d.recipient)
    set("shipping_city",           d.city)
    set("shipping_street",         d.street)
    set("shipping_street_number",  d.streetNumber)
    set("shipping_apartment",      d.apartment)

    // Region + comunas cascade
    set("shipping_region", d.region)
    if (this.hasRegionSelectTarget) {
      this.regionSelectTarget.value = d.region
      this.populateComunas(d.region, d.comuna)
    }

    // Phone: update number field
    const phone = d.phone || ""
    const knownPfx = ["+1809","+1","+7","+20","+27","+30","+31","+32","+33","+34",
      "+36","+39","+40","+41","+43","+44","+45","+46","+47","+48","+49","+51","+52",
      "+53","+54","+55","+56","+57","+58","+60","+61","+62","+63","+64","+65","+66",
      "+81","+82","+84","+86","+90","+91","+92","+93","+94","+95","+98",
      "+212","+213","+216","+221","+233","+234","+237","+244","+251","+254",
      "+260","+263","+351","+352","+353","+355","+356","+357","+358","+359",
      "+370","+371","+372","+373","+374","+380","+381","+385","+386","+387",
      "+420","+421","+501","+502","+503","+504","+505","+506","+507","+509",
      "+591","+593","+595","+598","+673","+855","+856","+880","+886",
      "+961","+962","+963","+964","+965","+966","+967","+968","+971","+972",
      "+973","+974","+977","+994","+995","+998"]
    const pfx    = knownPfx.find(p => phone.startsWith(p)) || "+56"
    const numStr = phone.slice(pfx.length).trim()
    set("shipping_phone_number", numStr)

    // Show address form
    if (this.hasAddressFormTarget) {
      this.addressFormTarget.classList.remove("hidden")
    }

    // Highlight selected card
    event.currentTarget.closest("#saved-addresses")
      ?.querySelectorAll("button")
      .forEach(b => b.classList.remove("border-stone-900", "bg-stone-50"))
    event.currentTarget.classList.add("border-stone-900", "bg-stone-50")
  }

  // "Ingresar una dirección diferente" — clears form and shows it
  newAddress() {
    ["shipping_recipient_name","shipping_city","shipping_street",
     "shipping_street_number","shipping_apartment"].forEach(name => {
      const el = this.element.querySelector(`[name='order[${name}]']`)
      if (el) el.value = ""
    })
    if (this.hasRegionSelectTarget) {
      this.regionSelectTarget.value = ""
      this.populateComunas("")
    }
    this.element.querySelector("#saved-addresses")
      ?.querySelectorAll("button")
      .forEach(b => b.classList.remove("border-stone-900", "bg-stone-50"))

    // Show form
    if (this.hasAddressFormTarget) {
      this.addressFormTarget.classList.remove("hidden")
    }

    // Scroll to form
    this.addressFormTarget?.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  clearAddress() {
    this.newAddress()
  }

  // ── Cascade región → comuna ──────────────────────────────

  regionChanged(event) {
    this.populateComunas(event.target.value)
  }

  populateComunas(region, selectedComuna = null) {
    if (!this.hasComunaSelectTarget) return

    const comunas = REGIONS[region] || []
    const select  = this.comunaSelectTarget

    select.innerHTML = '<option value="">— Selecciona una comuna —</option>'
    comunas.forEach(comuna => {
      const option       = document.createElement("option")
      option.value       = comuna
      option.textContent = comuna
      if (comuna === selectedComuna) option.selected = true
      select.appendChild(option)
    })

    select.disabled = comunas.length === 0
  }

  // ── Shipping type toggle ─────────────────────────────────

  shippingTypeChanged(event) {
    const isDelivery = event.target.value === "delivery"
    if (this.hasShippingSectionTarget) {
      this.shippingSectionTarget.classList.toggle("hidden", !isDelivery)
    }
  }

  // ── Apartment toggle ─────────────────────────────────────

  // Checkbox "Es casa" → HIDES the apartment field when checked
  toggleApartment(event) {
    if (!this.hasApartmentWrapperTarget) return
    const isHouse = event.target.checked
    this.apartmentWrapperTarget.classList.toggle("hidden", isHouse)
    if (isHouse && this.hasApartmentFieldTarget) {
      this.apartmentFieldTarget.value = ""
    }
  }

  // ── Document type placeholder ────────────────────────────

  documentTypeChanged(event) {
    if (!this.hasDocumentNumberTarget) return
    const placeholders = { rut: "Ej: 12.345.678-9", passport: "Ej: AB123456", dni: "Ej: 12345678" }
    this.documentNumberTarget.placeholder = placeholders[event.target.value] || ""
  }
}
