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
  static targets = ["list", "input", "form", "empty", "roster", "reactionTemplate"]
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
          if (data.reaction) this.renderReaction(data.reaction)
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

  // Picker emitted a chosen emoji (reaction-picker:selected). Toggle it.
  react(event) {
    const { kind, messageId } = event.detail
    if (!kind || !messageId) return
    this.subscription.perform("react", { message_id: Number(messageId), kind })
  }

  // Clicking an existing pill toggles the viewer's reaction of that kind.
  toggleKind(event) {
    const pill = event.currentTarget
    const messageId = pill.closest("[data-message-id]")?.dataset.messageId
    if (!messageId) return
    this.subscription.perform("react", {
      message_id: Number(messageId),
      kind: pill.dataset.kind,
    })
  }

  // Apply a broadcast reaction change. `count` is authoritative from the
  // server; each client only adjusts its own highlight (when it is the actor).
  renderReaction({ message_id, kind, emoji, user_id, state, count }) {
    const container = this.listTarget.querySelector(
      `[data-reactions-for="${message_id}"]`,
    )
    if (!container) return

    let pill = container.querySelector(`[data-reaction-pill][data-kind="${kind}"]`)

    if (count <= 0) {
      if (pill) pill.remove()
      return
    }

    if (!pill) {
      pill = this.#buildReactionPill(kind, emoji)
      container.appendChild(pill)
    }
    pill.querySelector("[data-reaction-count]").textContent = count

    if (user_id === this.userIdValue) {
      this.#setPillMine(pill, state === "added")
    }
  }

  appendMessage(message) {
    if (this.hasEmptyTarget) this.emptyTarget.remove()

    // Only the latest message carries read avatars, so clear the previous
    // message's markers before the new one becomes the latest.
    this.#clearReceipts()

    const mine = message.user_id === this.userIdValue

    const wrapper = document.createElement("div")
    wrapper.className = `group flex flex-col ${mine ? "items-end" : "items-start"}`
    wrapper.dataset.messageId = message.id

    const meta = document.createElement("span")
    meta.className = "px-1 text-xs text-muted-color"
    meta.textContent = mine ? "You" : message.sender_label

    const row = document.createElement("div")
    row.className = `mt-0.5 flex items-center gap-1 ${mine ? "flex-row-reverse" : ""}`

    const bubble = document.createElement("div")
    bubble.className = mine
      ? "max-w-[75%] rounded-2xl rounded-br-sm bg-brand-600 px-3 py-2 text-sm text-white"
      : "max-w-[75%] rounded-2xl rounded-bl-sm bg-surface-raised border border-surface px-3 py-2 text-sm text-base-color"
    bubble.textContent = message.body

    row.appendChild(bubble)
    const picker = this.#reactionPicker()
    if (picker) row.appendChild(picker)

    const reactions = document.createElement("div")
    reactions.className = "flex flex-wrap gap-1 px-1 mt-1"
    reactions.dataset.reactionsFor = message.id

    const receipts = document.createElement("div")
    receipts.className = "flex flex-wrap gap-1 px-1 mt-1.5"
    receipts.dataset.receiptsFor = message.id

    wrapper.appendChild(meta)
    wrapper.appendChild(row)
    wrapper.appendChild(reactions)
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

  // Clone the hidden reaction-picker template so live messages get the same
  // hover affordance as server-rendered ones.
  #reactionPicker() {
    if (!this.hasReactionTemplateTarget) return null
    return this.reactionTemplateTarget.content.cloneNode(true)
  }

  #buildReactionPill(kind, emoji) {
    const pill = document.createElement("button")
    pill.type = "button"
    pill.dataset.reactionPill = ""
    pill.dataset.kind = kind
    pill.dataset.action = "click->conversation#toggleKind"
    this.#setPillMine(pill, false)

    const emojiSpan = document.createElement("span")
    emojiSpan.textContent = emoji

    const countSpan = document.createElement("span")
    countSpan.dataset.reactionCount = ""

    pill.appendChild(emojiSpan)
    pill.appendChild(countSpan)
    return pill
  }

  // Class lists kept in sync with the server-rendered _reactions partial.
  #setPillMine(pill, mine) {
    pill.className =
      "inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs " +
      (mine ? "border-brand-500 bg-brand-50 dark:bg-brand-950" : "border-surface bg-surface-raised")
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
