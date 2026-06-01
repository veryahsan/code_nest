import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Subscribes to a single ConversationChannel and renders messages pushed
// over the Redis-backed Action Cable stream. New messages are sent back
// over the same channel (no full page round-trip).
export default class extends Controller {
  static targets = ["list", "input", "form", "empty"]
  static values = { id: Number, userId: Number }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "ConversationChannel", id: this.idValue },
      {
        received: (data) => {
          if (data && data.message) this.appendMessage(data.message)
        },
      },
    )
    this.scrollToBottom()
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
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

    const mine = message.user_id === this.userIdValue

    const wrapper = document.createElement("div")
    wrapper.className = `flex flex-col ${mine ? "items-end" : "items-start"}`

    const meta = document.createElement("span")
    meta.className = "px-1 text-xs text-muted-color"
    meta.textContent = mine ? "You" : message.sender_label

    const bubble = document.createElement("div")
    bubble.className = mine
      ? "mt-0.5 max-w-[75%] rounded-2xl rounded-br-sm bg-brand-600 px-3 py-2 text-sm text-white"
      : "mt-0.5 max-w-[75%] rounded-2xl rounded-bl-sm bg-surface-raised border border-surface px-3 py-2 text-sm text-base-color"
    bubble.textContent = message.body

    wrapper.appendChild(meta)
    wrapper.appendChild(bubble)
    this.listTarget.appendChild(wrapper)
    this.scrollToBottom()
  }

  scrollToBottom() {
    if (this.hasListTarget) {
      this.listTarget.scrollTop = this.listTarget.scrollHeight
    }
  }
}
