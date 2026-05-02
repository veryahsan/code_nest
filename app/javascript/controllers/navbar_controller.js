/**
 * Burger toggles the nav dropdown by adding/removing Tailwind `hidden` on the panel.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggle"]

  connect() {
    this.#boundKey = (e) => {
      if (e.key === "Escape" && this.#isOpen) this.close()
    }
    document.addEventListener("keydown", this.#boundKey)
    this.#boundDoc = (e) => {
      if (this.#isOpen && !this.element.contains(e.target)) this.close()
    }
    document.addEventListener("click", this.#boundDoc)
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundKey)
    document.removeEventListener("click", this.#boundDoc)
  }

  toggle(event) {
    event.stopPropagation()
    this.panelTarget.classList.toggle("hidden")
    this.#syncAria()
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.#syncAria()
  }

  get #isOpen() {
    return !this.panelTarget.classList.contains("hidden")
  }

  #syncAria() {
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", this.#isOpen.toString())
    }
  }

  #boundKey = null
  #boundDoc = null
}
