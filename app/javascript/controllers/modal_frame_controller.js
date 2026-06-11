/**
 * Modal Frame Controller — generic full-screen overlay for show pages.
 *
 * Attached to the persistent <turbo-frame id="modal"> host (shared/_modal_host).
 * A show page renders into this frame in two ways:
 *
 *   1. Link click (data-turbo-frame="modal"): Turbo loads the show page into the
 *      frame, the server wraps it in overlay chrome (a backdrop plus a 95vw/95vh
 *      panel), and close() returns to the page the overlay was opened from.
 *   2. Deep / full load (hard reload, bookmark, typed URL): the modal_show
 *      layout seeds the host with the overlay already filled. There is no
 *      underlying page, so close() navigates to the fallbackUrl (the parent
 *      collection) instead of going back.
 *
 * This controller's job is to:
 *   - reveal the frame once it has content (turbo:frame-load)
 *   - lock body scroll while the overlay is open
 *   - close on Escape, backdrop click, or a close control
 *   - clear the frame on close and restore the underlying page / parent URL
 *
 * The overlay markup inside the frame wires the backdrop/close button to
 * `modal-frame#close` via data-action (delegated through the host element).
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { fallbackUrl: String }

  connect() {
    this.#boundKey = (e) => { if (e.key === "Escape" && this.#hasContent) this.close() }
    document.addEventListener("keydown", this.#boundKey)
    // A frame seeded on a deep/full load has no prior in-app history to return
    // to on close; remember that so close() can fall back to the parent index.
    this.#deepLoaded = this.#hasContent
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

    // A modal seeded on a deep/full load has no underlying page: go to the
    // parent collection instead of leaving a blank screen behind.
    if (this.#deepLoaded) {
      this.#deepLoaded = false
      window.location.assign(this.fallbackUrlValue || "/")
      return
    }

    // Otherwise drop the show path from the address bar, returning to the page
    // the overlay was opened from.
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
  #deepLoaded = false

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
