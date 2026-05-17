/**
 * Confirm Controller
 *
 * Mounted on the shared confirm dialog (`#cn-confirm-dialog`, see
 * `shared/_confirm_dialog.html.erb`). On connect it registers itself as
 * Turbo's confirm method, so every element carrying
 *   data: { turbo_confirm: "..." }
 * opens this styled modal instead of `window.confirm()`.
 *
 * Per-trigger overrides (read from the submitting element's dataset):
 *   data-confirm-title    Custom heading text.
 *   data-confirm-button   Custom confirm-button label.
 *   data-confirm-variant  "danger" (default) | "primary"
 *
 * Resolves the Promise with:
 *   true   if the user clicks Confirm
 *   false  if the user clicks Cancel, presses Escape, or clicks the backdrop
 */
import { Controller } from "@hotwired/stimulus"

const DEFAULT_TITLE   = "Confirm action"
const DEFAULT_MESSAGE = "Are you sure?"
const DEFAULT_BUTTON  = "Confirm"
const DEFAULT_VARIANT = "danger"
const VARIANT_CLASSES = {
  danger:  "btn-danger",
  primary: "btn-primary",
}

export default class extends Controller {
  static targets = ["title", "message", "confirmBtn", "cancelBtn"]

  connect() {
    if (window.Turbo && typeof window.Turbo.setConfirmMethod === "function") {
      window.Turbo.setConfirmMethod((message, _formElement, submitter) =>
        this.prompt(message, submitter)
      )
    }

    this.element.addEventListener("modal:closed", this.#onClosed)
  }

  disconnect() {
    this.element.removeEventListener("modal:closed", this.#onClosed)
    this.#resolvePending(false)
  }

  // ── Public actions (wired in the partial via data-action) ────────────────

  accept() {
    this.#resolvePending(true)
    this.#close()
  }

  cancel() {
    this.#resolvePending(false)
    this.#close()
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  prompt(message, submitter) {
    // Resolve any prior outstanding promise as cancelled so we never leave one
    // dangling if Turbo somehow fires twice without a close in between.
    this.#resolvePending(false)

    const ds = (submitter && submitter.dataset) || {}

    this.titleTarget.textContent      = ds.confirmTitle  || DEFAULT_TITLE
    this.messageTarget.textContent    = message || DEFAULT_MESSAGE
    this.confirmBtnTarget.textContent = ds.confirmButton || DEFAULT_BUTTON

    const variant = (ds.confirmVariant || DEFAULT_VARIANT).toLowerCase()
    const variantClass = VARIANT_CLASSES[variant] || VARIANT_CLASSES[DEFAULT_VARIANT]
    Object.values(VARIANT_CLASSES).forEach((cls) =>
      this.confirmBtnTarget.classList.remove(cls)
    )
    this.confirmBtnTarget.classList.add(variantClass)

    this.element.dispatchEvent(new CustomEvent("modal:open"))
    // Focus Cancel rather than the destructive button so Enter/Space defaults
    // to the safe choice.
    requestAnimationFrame(() => this.cancelBtnTarget.focus())

    return new Promise((resolve) => {
      this.#pendingResolve = resolve
    })
  }

  #pendingResolve = null

  #onClosed = () => {
    // Modal dismissed via Escape / backdrop / external `modal:close` event:
    // treat as a cancel.
    this.#resolvePending(false)
  }

  #close() {
    this.element.dispatchEvent(new CustomEvent("modal:close"))
  }

  #resolvePending(value) {
    if (this.#pendingResolve) {
      const resolve = this.#pendingResolve
      this.#pendingResolve = null
      resolve(value)
    }
  }
}
