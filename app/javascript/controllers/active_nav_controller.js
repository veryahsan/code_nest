/**
 * Active Nav Controller — keeps the menu capsule's active tab in sync.
 *
 * The capsule lives in the application layout, OUTSIDE the persistent `main`
 * Turbo Frame that page links target. Because Turbo only swaps the frame's
 * inner content on navigation, the capsule is never re-rendered and the
 * server-computed active state would freeze on the first full-page load.
 *
 * This controller recomputes the active link on the client after every
 * navigation by matching each link's path against window.location.pathname:
 * exact match for the root, prefix match for sections (so a project's show
 * page keeps the Projects tab active).
 *
 * Markup: add data-active-nav-target="link" to each nav link and provide the
 * active/inactive class lists via values.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]
  static values = {
    active:   String,
    inactive: String,
    activeIcon:   { type: String, default: "" },
    inactiveIcon: { type: String, default: "" },
  }

  connect() {
    this.#bound = () => this.refresh()
    document.addEventListener("turbo:load", this.#bound)
    document.addEventListener("turbo:frame-load", this.#bound)
    this.refresh()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.#bound)
    document.removeEventListener("turbo:frame-load", this.#bound)
  }

  refresh() {
    const current = this.#normalize(window.location.pathname)

    this.linkTargets.forEach((link) => {
      const linkPath = this.#normalize(new URL(link.href, window.location.origin).pathname)
      const isActive =
        linkPath === "" || linkPath === "/"
          ? current === linkPath
          : current === linkPath || current.startsWith(`${linkPath}/`)

      this.#applyClasses(link, isActive)
    })
  }

  // ── private ────────────────────────────────────────────────────────────────

  #bound = null

  #normalize(path) {
    return (path || "").replace(/\/+$/, "")
  }

  #applyClasses(link, isActive) {
    const add    = (isActive ? this.activeValue : this.inactiveValue).split(/\s+/).filter(Boolean)
    const remove = (isActive ? this.inactiveValue : this.activeValue).split(/\s+/).filter(Boolean)
    link.classList.remove(...remove)
    link.classList.add(...add)
    if (isActive) {
      link.setAttribute("aria-current", "page")
    } else {
      link.removeAttribute("aria-current")
    }

    // Sync the icon color too, if icon class lists were provided.
    if (this.activeIconValue || this.inactiveIconValue) {
      const icon = link.querySelector("svg")
      if (icon) {
        const addI    = (isActive ? this.activeIconValue : this.inactiveIconValue).split(/\s+/).filter(Boolean)
        const removeI = (isActive ? this.inactiveIconValue : this.activeIconValue).split(/\s+/).filter(Boolean)
        icon.classList.remove(...removeI)
        icon.classList.add(...addI)
      }
    }
  }
}
