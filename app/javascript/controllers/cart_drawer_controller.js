import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop", "items", "emptyState", "footer", "count", "subtotal"]
  static values  = { open: Boolean }

  connect() {
    // Refresh drawer data whenever Turbo updates the cart-count frame
    // (fires after add-to-cart / remove turbo stream)
    document.addEventListener("turbo:frame-render", this.onFrameRender)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-render", this.onFrameRender)
  }

  onFrameRender = (event) => {
    if (event.target?.id === "cart-count") {
      this.fetchData()
    }
  }

  // ── Toggle ──────────────────────────────────────────────

  toggle() {
    this.openValue ? this.close() : this.open()
  }

  open() {
    this.openValue = true
    this.panelTarget.classList.remove("translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
    })
    document.body.style.overflow = "hidden"
    this.fetchData()
  }

  close() {
    this.openValue = false
    this.panelTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("opacity-0")
    setTimeout(() => this.backdropTarget.classList.add("hidden"), 300)
    document.body.style.overflow = ""
  }

  // ── Data fetching ────────────────────────────────────────

  async fetchData() {
    try {
      const res = await fetch("/carrito/datos", {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      if (!res.ok) return
      const data = await res.json()
      this.render(data)
    } catch (e) {
      // silently fail — drawer just won't update
    }
  }

  // ── Render ───────────────────────────────────────────────

  render(data) {
    const { count, subtotal, items } = data

    // Update count badge in drawer header
    if (this.hasCountTarget) this.countTarget.textContent = count

    if (!items || items.length === 0) {
      this.itemsTarget.classList.add("hidden")
      this.emptyStateTarget.classList.remove("hidden")
      this.footerTarget.classList.add("hidden")
      return
    }

    this.emptyStateTarget.classList.add("hidden")
    this.itemsTarget.classList.remove("hidden")
    this.footerTarget.classList.remove("hidden")

    this.itemsTarget.innerHTML = items.map(item => `
      <div class="flex items-center gap-3">
        <div class="w-14 h-14 rounded-xl bg-stone-100 overflow-hidden shrink-0 border border-stone-100">
          ${item.image_url
            ? `<img src="${item.image_url}" alt="${this.esc(item.name)}" class="w-full h-full object-cover">`
            : `<div class="w-full h-full flex items-center justify-center">
                 <span class="material-symbols-outlined text-stone-300 text-xl">inventory_2</span>
               </div>`
          }
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-stone-800 truncate">${this.esc(item.name)}</p>
          <p class="text-xs text-stone-400 mt-0.5">${this.esc(item.unit_price)} × ${item.quantity}</p>
        </div>
        <p class="text-sm font-semibold text-stone-900 shrink-0">${this.esc(item.total_price)}</p>
      </div>
    `).join('<div class="border-t border-stone-100 my-1"></div>')

    if (this.hasSubtotalTarget) this.subtotalTarget.textContent = subtotal
  }

  esc(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
