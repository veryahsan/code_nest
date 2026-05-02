/**
 * Loader Controller — swap button content with a spinner on form submit / async.
 *
 * Usage on a submit button:
 *   <button type="submit"
 *           data-controller="loader"
 *           data-loader-label-value="Creating…"
 *           data-action="click->loader#start">
 *     Create project
 *   </button>
 *
 * The button's text is replaced with a spinner + label while loading.
 * Turbo automatically fires turbo:submit-end which calls #stop.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    label:   { type: String, default: "Loading…" },
    timeout: { type: Number, default: 30_000 },   // safety reset after N ms
  }

  connect() {
    this.#originalHTML = this.element.innerHTML
    this.element.form?.addEventListener("turbo:submit-end", () => this.stop())
  }

  disconnect() {
    this.#clearTimeout()
  }

  start() {
    if (this.#loading) return
    this.#loading = true
    this.#originalHTML = this.element.innerHTML

    this.element.disabled = true
    this.element.innerHTML = this.#spinnerHTML(this.labelValue)
    this.#safetyTimer = setTimeout(() => this.stop(), this.timeoutValue)
  }

  stop() {
    if (!this.#loading) return
    this.#loading = false
    this.element.disabled = false
    this.element.innerHTML = this.#originalHTML
    this.#clearTimeout()
  }

  // ── private ────────────────────────────────────────────────────────────────

  #loading = false
  #originalHTML = ""
  #safetyTimer = null

  #spinnerHTML(label) {
    return `
      <svg class="animate-spin h-4 w-4 text-current" xmlns="http://www.w3.org/2000/svg"
           fill="none" viewBox="0 0 24 24" aria-hidden="true">
        <circle class="opacity-25" cx="12" cy="12" r="10"
                stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
      </svg>
      <span>${label}</span>
    `
  }

  #clearTimeout() {
    if (this.#safetyTimer) clearTimeout(this.#safetyTimer)
  }
}
