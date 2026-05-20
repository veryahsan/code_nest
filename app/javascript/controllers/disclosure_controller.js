/**
 * Disclosure Controller — inline accordion toggle.
 *
 * Lighter-weight than `dropdown_controller.js`: no outside-click handling,
 * no floating-panel positioning. Just flips `hidden` on a `panel` target,
 * rotates an optional `chevron` target, and keeps `aria-expanded` in sync
 * on the `trigger`.
 *
 * Markup pattern:
 *   <div data-controller="disclosure">
 *     <button data-action="click->disclosure#toggle"
 *             data-disclosure-target="trigger"
 *             aria-expanded="false">
 *       Section
 *       <svg data-disclosure-target="chevron" class="transition-transform">…</svg>
 *     </button>
 *     <div data-disclosure-target="panel" class="hidden">…</div>
 *   </div>
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "trigger", "chevron"]

  toggle(event) {
    event?.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.chevronTarget?.classList.add("rotate-180")
    this.triggerTarget?.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.chevronTarget?.classList.remove("rotate-180")
    this.triggerTarget?.setAttribute("aria-expanded", "false")
  }

  get isOpen() {
    return !this.panelTarget.classList.contains("hidden")
  }
}
