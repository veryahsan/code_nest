import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Subscribes to a single ConversationChannel and renders messages pushed
// over the Redis-backed Action Cable stream. New messages are sent back
// over the same channel (no full page round-trip).
//
// Read receipts: only the latest message shows avatars. While connected and
// visible, the client marks itself read (over the channel), which broadcasts a
// { user_id, last_message_id } event. Other clients clone that user's avatar
// from the hidden roster and place it under the latest message.
export default class extends Controller {
  static targets = ["list", "input", "form", "empty", "roster"]
  static values = { id: Number, userId: Number }

  connect() {
    this.lastMessageId = this.#currentLastMessageId()

    this.subscription = consumer.subscriptions.create(
      { channel: "ConversationChannel", id: this.idValue },
      {
        connected: () => {
          if (document.visibilityState === "visible") this.scheduleRead()
        },
        received: (data) => {
          if (!data) return
          if (data.message) {
            this.appendMessage(data.message)
            if (
              data.message.user_id !== this.userIdValue &&
              document.visibilityState === "visible"
            ) {
              this.scheduleRead()
            }
          }
          if (data.read_receipt) this.applyReadReceipt(data.read_receipt)
        },
      },
    )

    // Messages that arrive while the tab is hidden are marked read once the
    // user returns to the conversation.
    this.onVisibilityChange = () => {
      if (document.visibilityState === "visible") this.scheduleRead()
    }
    document.addEventListener("visibilitychange", this.onVisibilityChange)

    this.scrollToBottom()
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
    clearTimeout(this.readTimer)
  }

  submit(event) {
    event.preventDefault()
    const body = this.inputTarget.value.trim()
    if (body === "") return

    this.subscription.perform("speak", { body })
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  appendMessage(message) {
    if (this.hasEmptyTarget) this.emptyTarget.remove()

    // Only the latest message carries read avatars, so clear the previous
    // message's markers before the new one becomes the latest.
    this.#clearReceipts()

    const mine = message.user_id === this.userIdValue

    const wrapper = document.createElement("div")
    wrapper.className = `flex flex-col ${mine ? "items-end" : "items-start"}`
    wrapper.dataset.messageId = message.id

    const meta = document.createElement("span")
    meta.className = "px-1 text-xs text-muted-color"
    meta.textContent = mine ? "You" : message.sender_label

    const bubble = document.createElement("div")
    bubble.className = mine
      ? "mt-0.5 max-w-[75%] rounded-2xl rounded-br-sm bg-brand-600 px-3 py-2 text-sm text-white"
      : "mt-0.5 max-w-[75%] rounded-2xl rounded-bl-sm bg-surface-raised border border-surface px-3 py-2 text-sm text-base-color"
    bubble.textContent = message.body

    const receipts = document.createElement("div")
    receipts.className = "flex flex-wrap gap-1 px-1 mt-1.5"
    receipts.dataset.receiptsFor = message.id

    wrapper.appendChild(meta)
    wrapper.appendChild(bubble)
    wrapper.appendChild(receipts)
    this.listTarget.appendChild(wrapper)
    this.lastMessageId = message.id
    this.scrollToBottom()
  }

  // Tell the server we've read up to the latest message. Debounced so a burst
  // of incoming messages collapses into a single perform/broadcast.
  scheduleRead() {
    clearTimeout(this.readTimer)
    this.readTimer = setTimeout(() => this.subscription?.perform("read"), 400)
  }

  // Place a reader's avatar under the latest message. The viewer never sees
  // their own marker, and stale receipts (for a message that is no longer the
  // latest) are ignored.
  applyReadReceipt(receipt) {
    if (receipt.user_id === this.userIdValue) return
    if (receipt.last_message_id !== this.lastMessageId) return

    const existing = this.listTarget.querySelector(
      `[data-receipt-user="${receipt.user_id}"]`,
    )
    if (existing) existing.remove()

    const avatar = this.#rosterAvatar(receipt.user_id)
    if (!avatar) return

    const container = this.listTarget.querySelector(
      `[data-receipts-for="${this.lastMessageId}"]`,
    )
    if (container) container.appendChild(avatar)
  }

  // Clone the pre-rendered avatar for a participant from the hidden roster.
  #rosterAvatar(userId) {
    if (!this.hasRosterTarget) return null

    const source = this.rosterTarget.querySelector(
      `[data-roster-user="${userId}"]`,
    )
    if (!source) return null

    const clone = source.cloneNode(true)
    clone.removeAttribute("data-roster-user")
    clone.dataset.receiptUser = userId
    return clone
  }

  #clearReceipts() {
    this.listTarget
      .querySelectorAll("[data-receipt-user]")
      .forEach((node) => node.remove())
  }

  #currentLastMessageId() {
    const nodes = this.listTarget?.querySelectorAll("[data-message-id]")
    if (!nodes || nodes.length === 0) return null
    return Number(nodes[nodes.length - 1].dataset.messageId)
  }

  scrollToBottom() {
    if (this.hasListTarget) {
      this.listTarget.scrollTop = this.listTarget.scrollHeight
    }
  }
}
