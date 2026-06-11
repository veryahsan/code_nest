/**
 * Modal Frame Controller — generic full-screen overlay for show pages.
 *
 * Attached to the persistent <turbo-frame id="modal"> host in the application
 * layout. When a link targeting this frame loads a show page, the server wraps
 * the response (via layouts/modal_show.html.erb) in the overlay chrome — a
 * backdrop plus a 95vw/95vh panel. This controller's job is to:
 *
 *   - reveal the frame once it has content (turbo:frame-load)
 *   - lock body scroll while the overlay is open
 *   - close on Escape, backdrop click, or a [data-modal-frame-close] control
 *   - clear the frame on close and restore the underlying page URL
 *
 * The overlay markup inside the frame wires the backdrop/close button to
 * `modal-frame#close` via data-action (delegated through the host element).
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.#boundKey = (e) => { if (e.key === "Escape" && this.#hasContent) this.close() }
    document.addEventListener("keydown", this.#boundKey)
    // The frame may already hold content (e.g. restored from history); sync.
    this.#sync()
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundKey)
    this.#unlockScroll()
  }

  onFrameLoad() {
    this.#sync()
  }

  close(event) {
    event?.preventDefault()
    this.element.innerHTML = ""
    this.element.removeAttribute("src")
    this.element.removeAttribute("complete")
    this.#hide()

    // Drop the show path from the address bar, returning to the page the
    // overlay was opened from.
    if (this.#openedUrl && window.location.href === this.#openedUrl) {
      this.#openedUrl = null
      window.history.back()
    }
  }

  // Close only when the click landed on the backdrop itself, not its children.
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) this.close(event)
  }

  // ── private ────────────────────────────────────────────────────────────────

  #boundKey = null
  #openedUrl = null

  get #hasContent() {
    return this.element.children.length > 0
  }

  #sync() {
    this.#hasContent ? this.#show() : this.#hide()
  }

  #show() {
    this.element.classList.remove("hidden")
    this.#lockScroll()
    this.#openedUrl = window.location.href
    this.#focusFirst()
  }

  #hide() {
    this.element.classList.add("hidden")
    this.#unlockScroll()
  }

  #lockScroll() {
    document.body.style.overflow = "hidden"
  }

  #unlockScroll() {
    document.body.style.overflow = ""
  }

  #focusFirst() {
    const focusable = this.element.querySelector(
      'a[href], button:not([disabled]), input:not([disabled]), ' +
      'textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )
    focusable?.focus()
  }
}
