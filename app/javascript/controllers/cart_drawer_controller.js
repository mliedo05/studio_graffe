import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop", "items", "emptyState", "footer", "count", "subtotal"]
  static values  = { open: Boolean }

  connect() {
    this.loadFromData()

    // Re-render whenever Turbo updates the cart-count frame (add/remove item)
    document.addEventListener("turbo:frame-render", this.onFrameRender)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-render", this.onFrameRender)
  }

  onFrameRender = (event) => {
    if (event.target?.id === "cart-count") {
      // Small delay so the data island is also updated by Turbo
      setTimeout(() => this.loadFromData(), 50)
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
  }

  close() {
    this.openValue = false
    this.panelTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("opacity-0")
    setTimeout(() => this.backdropTarget.classList.add("hidden"), 300)
    document.body.style.overflow = ""
  }

  // ── Data ─────────────────────────────────────────────────

  loadFromData() {
    const el = document.getElementById("cart-drawer-data")
    if (!el) return

    let data
    try { data = JSON.parse(el.textContent) } catch { return }

    this.render(data)
  }

  render(data) {
    const { count, subtotal, items } = data

    // Update count badge
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

    // Render items
    this.itemsTarget.innerHTML = items.map(item => `
      <div class="flex items-center gap-3">
        <div class="w-14 h-14 rounded-xl bg-stone-100 overflow-hidden shrink-0 border border-stone-100">
          ${item.image_url
            ? `<img src="${item.image_url}" alt="${this.escHtml(item.name)}" class="w-full h-full object-cover">`
            : `<div class="w-full h-full flex items-center justify-center">
                 <span class="material-symbols-outlined text-stone-300 text-xl">inventory_2</span>
               </div>`
          }
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-stone-800 truncate">${this.escHtml(item.name)}</p>
          <p class="text-xs text-stone-400 mt-0.5">${this.escHtml(item.unit_price)} × ${item.quantity}</p>
        </div>
        <p class="text-sm font-semibold text-stone-900 shrink-0">${this.escHtml(item.total_price)}</p>
      </div>
    `).join('<div class="border-t border-stone-100"></div>')

    // Update subtotal
    if (this.hasSubtotalTarget) this.subtotalTarget.textContent = subtotal
  }

  escHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
