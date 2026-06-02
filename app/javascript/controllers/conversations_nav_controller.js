import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Keeps the sidebar conversation list's unread badges live:
//   - a NotificationsChannel broadcast bumps the badge for its conversation,
//     unless the user is already viewing that conversation
//   - opening a conversation (Turbo navigation to /conversations/:id) clears
//     its badge, mirroring the server-side mark-as-read in ConversationsController
//
// Counts are seeded server-side by SidebarFacade; this only adjusts them so the
// sidebar (which lives outside the Turbo main frame and does not re-render on
// frame navigation) stays accurate without a full reload.
export default class extends Controller {
  static targets = ["badge"]

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      { received: (data) => this.#onMessage(data) },
    )

    this.boundSync = () => this.#clearCurrent()
    document.addEventListener("turbo:load", this.boundSync)
    document.addEventListener("turbo:frame-load", this.boundSync)
    this.#clearCurrent()
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
    document.removeEventListener("turbo:load", this.boundSync)
    document.removeEventListener("turbo:frame-load", this.boundSync)
  }

  #onMessage(data) {
    if (data.conversation_id == null) return

    const id = String(data.conversation_id)
    if (id === this.#currentConversationId()) return

    const badge = this.#badgeFor(id)
    if (badge) this.#setCount(badge, this.#countOf(badge) + 1)
  }

  #clearCurrent() {
    const id = this.#currentConversationId()
    if (!id) return

    const badge = this.#badgeFor(id)
    if (badge) this.#setCount(badge, 0)
  }

  #currentConversationId() {
    const match = window.location.pathname.match(/\/conversations\/(\d+)/)
    return match ? match[1] : null
  }

  #badgeFor(id) {
    return this.badgeTargets.find((el) => el.dataset.conversationId === id)
  }

  #countOf(badge) {
    return parseInt(badge.dataset.count || "0", 10) || 0
  }

  #setCount(badge, count) {
    badge.dataset.count = count
    badge.textContent = count > 99 ? "99+" : count
    badge.classList.toggle("hidden", count <= 0)
  }
}
