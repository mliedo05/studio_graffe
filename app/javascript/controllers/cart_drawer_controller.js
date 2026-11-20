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
      <div class="sx-drawer__item">
        <div class="sx-drawer__thumb">
          ${item.image_url
            ? `<img src="${this.esc(item.image_url)}" alt="${this.esc(item.name)}">`
            : ""}
        </div>
        <div class="flex-1 min-w-0 flex flex-col">
          ${item.brand ? `<p class="sx-drawer__brand">${this.esc(item.brand)}</p>` : ""}
          <p class="sx-drawer__name">${this.esc(item.name)}</p>
          <div class="flex items-end mt-auto gap-3">
            <span class="sx-drawer__qty">Cant. ${Number(item.quantity)}</span>
            <span class="sx-drawer__price">${this.esc(item.total_price)}</span>
          </div>
        </div>
      </div>
    `).join("")

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
