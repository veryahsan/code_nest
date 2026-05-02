/**
 * Modal Controller
 *
 * Attach to the modal root element:
 *   <div id="confirm-modal" data-controller="modal" class="hidden ...">
 *
 * Open:  data-action="click->modal#open"   (must target the same controller)
 *        Or fire a custom event: element.dispatchEvent(new Event("modal:open"))
 *
 * Close: data-action="modal#close"
 *        Click the backdrop (data-action="click->modal#closeOnBackdrop")
 *        Press Escape
 *
 * See _modal.html.erb for the full markup.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.#boundKeyHandler = this.#handleKey.bind(this)
    this.element.addEventListener("modal:open",  () => this.open())
    this.element.addEventListener("modal:close", () => this.close())
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundKeyHandler)
  }

  open() {
    this.element.classList.remove("hidden")
    document.addEventListener("keydown", this.#boundKeyHandler)
    document.body.style.overflow = "hidden"
    this.#focusFirst()
    this.dispatch("opened")
  }

  close() {
    this.element.classList.add("hidden")
    document.removeEventListener("keydown", this.#boundKeyHandler)
    document.body.style.overflow = ""
    this.dispatch("closed")
  }

  closeOnBackdrop(event) {
    // Only close if the click was directly on the backdrop, not the panel
    if (event.target === event.currentTarget) this.close()
  }

  // ── private ────────────────────────────────────────────────────────────────

  #boundKeyHandler = null

  #handleKey(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
    if (event.key === "Tab") this.#trapFocus(event)
  }

  #focusFirst() {
    const focusable = this.#focusableElements()
    focusable[0]?.focus()
  }

  #trapFocus(event) {
    const els = this.#focusableElements()
    if (!els.length) return
    const first = els[0]
    const last  = els[els.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  #focusableElements() {
    return Array.from(
      this.element.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), ' +
        'textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
    )
  }
}
