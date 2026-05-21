/**
 * Sidebar Controller — off-canvas drawer for the mobile nav.
 *
 * On <md the sidebar panel is hidden + translated off-screen. The mobile
 * topbar's burger triggers `open`, the overlay (and Escape) trigger `close`.
 * At md+ the panel is permanently visible via Tailwind (`md:flex md:translate-x-0`)
 * and these methods are no-ops as far as the user can see.
 *
 * Markup pattern (rendered from app/views/layouts/application.html.erb):
 *   <div data-controller="sidebar">
 *     <div data-sidebar-target="overlay" class="hidden ...">…</div>
 *     <aside data-sidebar-target="panel" class="hidden -translate-x-full ...">…</aside>
 *     <button data-action="click->sidebar#open">…</button>
 *   </div>
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]
  static values = { mainFrame: { type: String, default: "main" } }

  connect() {
    this.#boundKey       = (e) => { if (e.key === "Escape" && this.#isOpen) this.close() }
    this.#boundVisit     = () => this.close()
    this.#boundFrameLoad = (e) => {
      if (e.target.id === this.mainFrameValue) this.close()
    }
    document.addEventListener("keydown", this.#boundKey)
    document.addEventListener("turbo:visit", this.#boundVisit)
    document.addEventListener("turbo:frame-load", this.#boundFrameLoad)
  }

  disconnect() {
    document.removeEventListener("keydown", this.#boundKey)
    document.removeEventListener("turbo:visit", this.#boundVisit)
    document.removeEventListener("turbo:frame-load", this.#boundFrameLoad)
  }

  open() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("hidden", "-translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    this.overlayTarget?.classList.remove("hidden")
    this.#syncAria(true)
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("-translate-x-full")
    this.overlayTarget?.classList.add("hidden")
    // Keep `hidden` off at md+ via the responsive `md:flex` class. We add
    // `hidden` again only at small screens, after the slide-out transition
    // would have finished, to avoid focus-trap leaks.
    if (window.matchMedia("(max-width: 767px)").matches) {
      window.setTimeout(() => this.panelTarget.classList.add("hidden"), 200)
    }
    this.#syncAria(false)
  }

  toggle(event) {
    event?.stopPropagation()
    this.#isOpen ? this.close() : this.open()
  }

  // ── private ────────────────────────────────────────────────────────────────

  get #isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("-translate-x-full") &&
           !this.panelTarget.classList.contains("hidden")
  }

  #syncAria(open) {
    this.element.querySelectorAll('[aria-controls="sidebar-panel"]').forEach((btn) => {
      btn.setAttribute("aria-expanded", open.toString())
    })
  }

  #boundKey       = null
  #boundVisit     = null
  #boundFrameLoad = null
}
