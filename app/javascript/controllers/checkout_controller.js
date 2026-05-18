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
    "step", "stepIndicator",
    // Billing
    "documentNumber", "documentSelect",
    // Shipping
    "regionSelect", "comunaSelect", "shippingSection", "apartmentField", "apartmentWrapper",
    // Summary
    "summaryFirstName", "summaryLastName", "summaryDocument", "summaryEmail", "summaryPhone",
    "summaryShipping", "summaryAddress"
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
    const step = this.stepTargets[this.currentValue]
    const required = step.querySelectorAll("[required]")
    let valid = true

    required.forEach(field => {
      if (!field.value.trim()) {
        field.classList.add("border-red-400")
        field.addEventListener("input", () => field.classList.remove("border-red-400"), { once: true })
        valid = false
      }
    })

    if (!valid) {
      // Scroll to first invalid field
      const first = step.querySelector("[required]:placeholder-shown, [required]:invalid")
      first?.scrollIntoView({ behavior: "smooth", block: "center" })
    }

    // Step 2: if delivery, validate address fields
    if (this.currentValue === 1) {
      const isDelivery = step.querySelector("[value='delivery']")?.checked
      if (isDelivery) {
        const addressFields = ["shipping_region", "shipping_comuna", "shipping_city", "shipping_street", "shipping_street_number", "shipping_recipient_name", "shipping_phone"]
        addressFields.forEach(name => {
          const el = step.querySelector(`[name='order[${name}]']`)
          if (el && !el.value.trim()) {
            el.classList.add("border-red-400")
            el.addEventListener("input", () => el.classList.remove("border-red-400"), { once: true })
            valid = false
          }
        })
      }
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
      this.summaryPhoneTarget.textContent      = `+56 ${get("billing_phone")}`
    }

    if (this.hasSummaryShippingTarget) {
      const isDelivery = this.element.querySelector("[value='delivery']")?.checked
      this.summaryShippingTarget.textContent = isDelivery ? "Delivery a domicilio" : "Retiro en tienda"

      if (this.hasSummaryAddressTarget) {
        if (isDelivery) {
          const parts = [get("shipping_street"), get("shipping_street_number"), get("shipping_apartment"), get("shipping_comuna"), get("shipping_region")].filter(Boolean)
          this.summaryAddressTarget.textContent = parts.join(", ")
          this.summaryAddressTarget.parentElement.classList.remove("hidden")
        } else {
          this.summaryAddressTarget.parentElement.classList.add("hidden")
        }
      }
    }
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

  toggleApartment(event) {
    if (!this.hasApartmentWrapperTarget) return
    this.apartmentWrapperTarget.classList.toggle("hidden", !event.target.checked)
    if (!event.target.checked && this.hasApartmentFieldTarget) {
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
