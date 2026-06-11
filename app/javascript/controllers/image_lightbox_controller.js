/**
 * Image Lightbox Controller
 *
 * Attach to a container that holds rendered message bodies (e.g. the
 * conversation root). It listens, via delegation, for clicks on any
 * `.trix-content img` inside the container — including live-appended
 * messages — and opens the full-size image in the shared modal.
 *
 *   <div data-controller="image-lightbox"
 *        data-image-lightbox-modal-value="#image-lightbox-modal">
 *     ...message list with .trix-content img thumbnails...
 *   </div>
 *
 * The modal markup lives elsewhere on the page and carries
 * `data-image-lightbox-target="image"` on its <img>.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  static values  = { modal: String }

  connect() {
    this.#boundOnClick = this.#onClick.bind(this)
    this.element.addEventListener("click", this.#boundOnClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.#boundOnClick)
  }

  // ── private ────────────────────────────────────────────────────────────────

  #boundOnClick = null

  #onClick(event) {
    const img = event.target.closest(".trix-content img")
    if (!img || !this.element.contains(img)) return

    // Images are wrapped in an <a> linking to the full-size blob; intercept it
    // so the click opens the lightbox instead of navigating away.
    const link = img.closest("a")
    if (link) event.preventDefault()

    const fullSrc = link?.getAttribute("href") || img.currentSrc || img.src
    if (!fullSrc) return

    const modal = this.#modalElement()
    if (!modal) return

    const target = modal.querySelector('[data-image-lightbox-target="image"]')
                || this.#imageTarget()
    if (target) {
      target.src = fullSrc
      target.alt = img.alt || ""
    }

    modal.dispatchEvent(new CustomEvent("modal:open"))
  }

  #modalElement() {
    if (this.hasModalValue && this.modalValue) {
      return document.querySelector(this.modalValue)
    }
    return this.hasImageTarget ? this.imageTarget.closest('[data-controller~="modal"]') : null
  }

  #imageTarget() {
    return this.hasImageTarget ? this.imageTarget : null
  }
}
