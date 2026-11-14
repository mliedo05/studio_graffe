import { Controller } from "@hotwired/stimulus"

// Hero de la portada: recorrido 3D por el salón (line art) guiado por el scroll.
// Three.js se importa recién aquí, así que el resto del sitio no lo descarga.
export default class extends Controller {
  static targets = ["canvas", "step", "bar", "hint"]

  async connect() {
    if (!this.webglAvailable()) return this.fallback()
    try {
      const { createSalonScene } = await import("salon_scene")
      if (!this.element.isConnected) return
      this.destroyScene = createSalonScene({
        hero: this.element,
        canvas: this.canvasTarget,
        steps: this.stepTargets,
        bars: this.barTargets,
        hint: this.hasHintTarget ? this.hintTarget : null
      })
      this.element.classList.add("is-3d")
    } catch (error) {
      console.error("[salon-hero]", error)
      this.fallback()
    }
  }

  disconnect() {
    this.destroyScene?.()
    this.destroyScene = null
  }

  // Sin WebGL: portada estática con el primer texto y sin recorrido
  fallback() {
    this.element.classList.add("is-static")
  }

  webglAvailable() {
    try {
      const c = document.createElement("canvas")
      return !!(window.WebGLRenderingContext && (c.getContext("webgl2") || c.getContext("webgl")))
    } catch { return false }
  }
}
