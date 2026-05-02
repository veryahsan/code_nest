/**
 * Dismissible Controller — remove an element from the DOM with a fade.
 *
 * Usage:
 *   <div data-controller="dismissible">
 *     Content to dismiss
 *     <button data-action="dismissible#dismiss">×</button>
 *   </div>
 *
 * Used by the _alert partial when dismissible: true.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } }

  connect() {
    if (this.delayValue > 0) {
      this.#timer = setTimeout(() => this.dismiss(), this.delayValue)
    }
  }

  disconnect() {
    clearTimeout(this.#timer)
  }

  dismiss() {
    this.element.style.transition = "opacity 200ms ease, transform 200ms ease"
    this.element.style.opacity    = "0"
    this.element.style.transform  = "translateY(-4px)"
    setTimeout(() => this.element.remove(), 220)
  }

  // ── private ────────────────────────────────────────────────────────────────

  #timer = null
}
