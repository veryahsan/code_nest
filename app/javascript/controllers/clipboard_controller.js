/**
 * Clipboard Controller — copy text to clipboard with visual feedback.
 *
 * Usage:
 *   <div data-controller="clipboard" data-clipboard-text-value="text to copy">
 *     <button data-action="click->clipboard#copy"
 *             data-clipboard-target="button">
 *       Copy
 *     </button>
 *     <span data-clipboard-target="feedback" class="hidden text-xs text-success-600">
 *       Copied!
 *     </span>
 *   </div>
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "feedback"]
  static values  = {
    text:    String,
    success: { type: String, default: "Copied!" },
    timeout: { type: Number, default: 2000 },
  }

  async copy() {
    const text = this.hasTextValue ? this.textValue : this.#sourceText()
    if (!text) return

    try {
      await navigator.clipboard.writeText(text)
      this.#showFeedback()
    } catch {
      this.#fallbackCopy(text)
    }
  }

  // ── private ────────────────────────────────────────────────────────────────

  #timer = null

  #sourceText() {
    // If no text-value, look for a sibling <input> or <pre> to copy from
    const el = this.element.querySelector("input, textarea, pre, code")
    return el?.value || el?.textContent || ""
  }

  #showFeedback() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.classList.remove("hidden")
      clearTimeout(this.#timer)
      this.#timer = setTimeout(() => {
        this.feedbackTarget.classList.add("hidden")
      }, this.timeoutValue)
    }
    this.dispatch("copied", { detail: { text: this.textValue } })
  }

  #fallbackCopy(text) {
    const el = document.createElement("textarea")
    el.value = text
    el.style.position = "fixed"
    el.style.opacity  = "0"
    document.body.appendChild(el)
    el.select()
    document.execCommand("copy")
    document.body.removeChild(el)
    this.#showFeedback()
  }
}
