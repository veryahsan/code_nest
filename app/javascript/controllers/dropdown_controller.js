/**
 * Dropdown Controller — toggleable menu that closes on outside-click or Escape.
 *
 * Markup pattern:
 *   <div data-controller="dropdown" class="relative">
 *     <button data-action="click->dropdown#toggle" data-dropdown-target="trigger">
 *       Open menu
 *     </button>
 *     <div data-dropdown-target="menu"
 *          class="hidden absolute right-0 mt-1 w-48 rounded-lg border border-surface
 *                 bg-surface-raised shadow-card z-20 py-1">
 *       <a href="#" class="block px-4 py-2 text-sm hover:bg-zinc-100 dark:hover:bg-zinc-800">Item</a>
 *     </div>
 *   </div>
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "trigger"]

  connect() {
    this.#boundClose = this.#handleOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click",   this.#boundClose)
    document.removeEventListener("keydown", this.#keyClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click",   this.#boundClose)
    document.addEventListener("keydown", this.#keyClose)
    this.triggerTarget?.setAttribute("aria-expanded", "true")
    this.dispatch("opened")
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click",   this.#boundClose)
    document.removeEventListener("keydown", this.#keyClose)
    this.triggerTarget?.setAttribute("aria-expanded", "false")
    this.dispatch("closed")
  }

  get isOpen() {
    return !this.menuTarget.classList.contains("hidden")
  }

  // ── private ────────────────────────────────────────────────────────────────

  #boundClose = null

  #handleOutside = (event) => {
    if (!this.element.contains(event.target)) this.close()
  }

  #keyClose = (event) => {
    if (event.key === "Escape") this.close()
  }
}
