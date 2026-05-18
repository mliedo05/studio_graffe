import { Controller } from "@hotwired/stimulus"

const COUNTRIES = [
  { code: "+56",   flag: "🇨🇱", name: "Chile" },
  { code: "+54",   flag: "🇦🇷", name: "Argentina" },
  { code: "+591",  flag: "🇧🇴", name: "Bolivia" },
  { code: "+55",   flag: "🇧🇷", name: "Brasil" },
  { code: "+57",   flag: "🇨🇴", name: "Colombia" },
  { code: "+53",   flag: "🇨🇺", name: "Cuba" },
  { code: "+593",  flag: "🇪🇨", name: "Ecuador" },
  { code: "+503",  flag: "🇸🇻", name: "El Salvador" },
  { code: "+34",   flag: "🇪🇸", name: "España" },
  { code: "+1",    flag: "🇺🇸", name: "Estados Unidos" },
  { code: "+502",  flag: "🇬🇹", name: "Guatemala" },
  { code: "+504",  flag: "🇭🇳", name: "Honduras" },
  { code: "+39",   flag: "🇮🇹", name: "Italia" },
  { code: "+52",   flag: "🇲🇽", name: "México" },
  { code: "+505",  flag: "🇳🇮", name: "Nicaragua" },
  { code: "+507",  flag: "🇵🇦", name: "Panamá" },
  { code: "+595",  flag: "🇵🇾", name: "Paraguay" },
  { code: "+51",   flag: "🇵🇪", name: "Perú" },
  { code: "+351",  flag: "🇵🇹", name: "Portugal" },
  { code: "+44",   flag: "🇬🇧", name: "Reino Unido" },
  { code: "+1809", flag: "🇩🇴", name: "Rep. Dominicana" },
  { code: "+598",  flag: "🇺🇾", name: "Uruguay" },
  { code: "+58",   flag: "🇻🇪", name: "Venezuela" },
  { code: "+93",   flag: "🇦🇫", name: "Afganistán" },
  { code: "+355",  flag: "🇦🇱", name: "Albania" },
  { code: "+213",  flag: "🇩🇿", name: "Argelia" },
  { code: "+376",  flag: "🇦🇩", name: "Andorra" },
  { code: "+244",  flag: "🇦🇴", name: "Angola" },
  { code: "+374",  flag: "🇦🇲", name: "Armenia" },
  { code: "+61",   flag: "🇦🇺", name: "Australia" },
  { code: "+43",   flag: "🇦🇹", name: "Austria" },
  { code: "+994",  flag: "🇦🇿", name: "Azerbaiyán" },
  { code: "+973",  flag: "🇧🇭", name: "Baréin" },
  { code: "+880",  flag: "🇧🇩", name: "Bangladesh" },
  { code: "+32",   flag: "🇧🇪", name: "Bélgica" },
  { code: "+501",  flag: "🇧🇿", name: "Belice" },
  { code: "+975",  flag: "🇧🇹", name: "Bután" },
  { code: "+387",  flag: "🇧🇦", name: "Bosnia Herzegovina" },
  { code: "+267",  flag: "🇧🇼", name: "Botsuana" },
  { code: "+673",  flag: "🇧🇳", name: "Brunéi" },
  { code: "+359",  flag: "🇧🇬", name: "Bulgaria" },
  { code: "+855",  flag: "🇰🇭", name: "Camboya" },
  { code: "+237",  flag: "🇨🇲", name: "Camerún" },
  { code: "+1",    flag: "🇨🇦", name: "Canadá" },
  { code: "+86",   flag: "🇨🇳", name: "China" },
  { code: "+357",  flag: "🇨🇾", name: "Chipre" },
  { code: "+82",   flag: "🇰🇷", name: "Corea del Sur" },
  { code: "+506",  flag: "🇨🇷", name: "Costa Rica" },
  { code: "+385",  flag: "🇭🇷", name: "Croacia" },
  { code: "+45",   flag: "🇩🇰", name: "Dinamarca" },
  { code: "+20",   flag: "🇪🇬", name: "Egipto" },
  { code: "+251",  flag: "🇪🇹", name: "Etiopía" },
  { code: "+679",  flag: "🇫🇯", name: "Fiyi" },
  { code: "+358",  flag: "🇫🇮", name: "Finlandia" },
  { code: "+33",   flag: "🇫🇷", name: "Francia" },
  { code: "+995",  flag: "🇬🇪", name: "Georgia" },
  { code: "+233",  flag: "🇬🇭", name: "Ghana" },
  { code: "+30",   flag: "🇬🇷", name: "Grecia" },
  { code: "+509",  flag: "🇭🇹", name: "Haití" },
  { code: "+36",   flag: "🇭🇺", name: "Hungría" },
  { code: "+91",   flag: "🇮🇳", name: "India" },
  { code: "+62",   flag: "🇮🇩", name: "Indonesia" },
  { code: "+98",   flag: "🇮🇷", name: "Irán" },
  { code: "+964",  flag: "🇮🇶", name: "Irak" },
  { code: "+353",  flag: "🇮🇪", name: "Irlanda" },
  { code: "+972",  flag: "🇮🇱", name: "Israel" },
  { code: "+81",   flag: "🇯🇵", name: "Japón" },
  { code: "+962",  flag: "🇯🇴", name: "Jordania" },
  { code: "+254",  flag: "🇰🇪", name: "Kenia" },
  { code: "+965",  flag: "🇰🇼", name: "Kuwait" },
  { code: "+856",  flag: "🇱🇦", name: "Laos" },
  { code: "+371",  flag: "🇱🇻", name: "Letonia" },
  { code: "+961",  flag: "🇱🇧", name: "Líbano" },
  { code: "+218",  flag: "🇱🇾", name: "Libia" },
  { code: "+370",  flag: "🇱🇹", name: "Lituania" },
  { code: "+352",  flag: "🇱🇺", name: "Luxemburgo" },
  { code: "+212",  flag: "🇲🇦", name: "Marruecos" },
  { code: "+60",   flag: "🇲🇾", name: "Malasia" },
  { code: "+356",  flag: "🇲🇹", name: "Malta" },
  { code: "+52",   flag: "🇲🇽", name: "México" },
  { code: "+373",  flag: "🇲🇩", name: "Moldavia" },
  { code: "+977",  flag: "🇳🇵", name: "Nepal" },
  { code: "+31",   flag: "🇳🇱", name: "Países Bajos" },
  { code: "+64",   flag: "🇳🇿", name: "Nueva Zelanda" },
  { code: "+234",  flag: "🇳🇬", name: "Nigeria" },
  { code: "+47",   flag: "🇳🇴", name: "Noruega" },
  { code: "+968",  flag: "🇴🇲", name: "Omán" },
  { code: "+92",   flag: "🇵🇰", name: "Pakistán" },
  { code: "+63",   flag: "🇵🇭", name: "Filipinas" },
  { code: "+48",   flag: "🇵🇱", name: "Polonia" },
  { code: "+974",  flag: "🇶🇦", name: "Catar" },
  { code: "+40",   flag: "🇷🇴", name: "Rumanía" },
  { code: "+7",    flag: "🇷🇺", name: "Rusia" },
  { code: "+966",  flag: "🇸🇦", name: "Arabia Saudita" },
  { code: "+221",  flag: "🇸🇳", name: "Senegal" },
  { code: "+381",  flag: "🇷🇸", name: "Serbia" },
  { code: "+65",   flag: "🇸🇬", name: "Singapur" },
  { code: "+421",  flag: "🇸🇰", name: "Eslovaquia" },
  { code: "+386",  flag: "🇸🇮", name: "Eslovenia" },
  { code: "+27",   flag: "🇿🇦", name: "Sudáfrica" },
  { code: "+46",   flag: "🇸🇪", name: "Suecia" },
  { code: "+41",   flag: "🇨🇭", name: "Suiza" },
  { code: "+963",  flag: "🇸🇾", name: "Siria" },
  { code: "+886",  flag: "🇹🇼", name: "Taiwán" },
  { code: "+66",   flag: "🇹🇭", name: "Tailandia" },
  { code: "+216",  flag: "🇹🇳", name: "Túnez" },
  { code: "+90",   flag: "🇹🇷", name: "Turquía" },
  { code: "+380",  flag: "🇺🇦", name: "Ucrania" },
  { code: "+971",  flag: "🇦🇪", name: "Emiratos Árabes" },
  { code: "+998",  flag: "🇺🇿", name: "Uzbekistán" },
  { code: "+84",   flag: "🇻🇳", name: "Vietnam" },
  { code: "+967",  flag: "🇾🇪", name: "Yemen" },
  { code: "+260",  flag: "🇿🇲", name: "Zambia" },
  { code: "+263",  flag: "🇿🇼", name: "Zimbabue" },
]

export default class extends Controller {
  static targets = ["trigger", "triggerFlag", "triggerCode", "dropdown",
                    "search", "list", "hidden"]
  static values  = { selected: { type: String, default: "+56" } }

  connect() {
    this.allCountries = COUNTRIES
    this.renderList(this.allCountries)
    this.select(this.selectedValue, false)
    document.addEventListener("click", this.onOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.onOutsideClick)
  }

  // ── Toggle dropdown ───────────────────────────────────────────────
  toggle(e) {
    e.stopPropagation()
    const open = !this.dropdownTarget.classList.contains("hidden")
    if (open) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.dropdownTarget.classList.remove("hidden")
    this.searchTarget.value = ""
    this.renderList(this.allCountries)
    this.searchTarget.focus()
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
  }

  // ── Outside click ─────────────────────────────────────────────────
  onOutsideClick = (e) => {
    if (!this.element.contains(e.target)) this.close()
  }

  // ── Keyboard ──────────────────────────────────────────────────────
  onKeydown(e) {
    if (e.key === "Escape") this.close()
  }

  // ── Search ────────────────────────────────────────────────────────
  filter() {
    const q = this.searchTarget.value.toLowerCase().trim()
    const filtered = q
      ? this.allCountries.filter(c =>
          c.name.toLowerCase().includes(q) || c.code.includes(q))
      : this.allCountries
    this.renderList(filtered)
  }

  // ── Render list ───────────────────────────────────────────────────
  renderList(countries) {
    this.listTarget.innerHTML = countries.map(c => `
      <button type="button"
              data-code="${c.code}"
              data-action="click->phone-country#pick"
              class="w-full flex items-center gap-3 px-4 py-2.5 text-left
                     hover:bg-stone-50 transition-colors
                     ${c.code === this.selectedValue ? "bg-stone-100 font-semibold" : ""}">
        <span class="text-xl leading-none w-7 shrink-0">${c.flag}</span>
        <span class="flex-1 text-sm text-stone-800">${c.name}</span>
        <span class="text-xs text-stone-400 shrink-0">${c.code}</span>
      </button>
    `).join("")
  }

  // ── Pick a country ────────────────────────────────────────────────
  pick(e) {
    const code = e.currentTarget.dataset.code
    this.select(code, true)
    this.close()
  }

  select(code, rerender = true) {
    const country = this.allCountries.find(c => c.code === code) || this.allCountries[0]
    this.selectedValue = country.code
    this.triggerFlagTarget.textContent = country.flag
    this.triggerCodeTarget.textContent = country.code
    this.hiddenTarget.value = country.code
    if (rerender) this.renderList(this.allCountries)
  }
}
