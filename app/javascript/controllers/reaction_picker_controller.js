import { Controller } from "@hotwired/stimulus"

// Per-message emoji reaction picker. Toggles a small panel of quick reactions
// and closes on outside-click or Escape. Mirrors the dropdown controller, but
// scoped so each message bubble owns its own picker instance.
//
// Selecting an emoji currently just closes the panel. The `select` action is
// the single extension point for the upcoming reaction submission flow.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this.#boundClose = this.#handleOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.#boundClose)
    document.removeEventListener("keydown", this.#keyClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    document.addEventListener("click", this.#boundClose)
    document.addEventListener("keydown", this.#keyClose)
    this.element.setAttribute("aria-expanded", "true")
    this.triggerTarget?.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    document.removeEventListener("click", this.#boundClose)
    document.removeEventListener("keydown", this.#keyClose)
    this.element.setAttribute("aria-expanded", "false")
    this.triggerTarget?.setAttribute("aria-expanded", "false")
  }

  select(event) {
    const kind = event.currentTarget.dataset.reactionKind
    const messageId = this.element.closest("[data-message-id]")?.dataset.messageId

    // TODO(reactions): wire submission here. The data model (Reaction#kind) and
    // emoji set are already in place; dispatch/perform the create from here.
    this.dispatch("selected", { detail: { kind, messageId } })

    this.close()
  }

  get isOpen() {
    return !this.panelTarget.classList.contains("hidden")
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
