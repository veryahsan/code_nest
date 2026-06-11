import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Subscribes to the per-user NotificationsChannel and keeps the sidebar bell
// in sync: live broadcasts prepend a row and bump the unread badge, the badge
// hides at zero, and mark-as-read interactions update the count optimistically
// while the server persists the change.
//
// Live rows are built to mirror app/views/notifications/_notification.html.erb
// so server-seeded and pushed items look and behave identically.
export default class extends Controller {
  static targets = ["badge", "list", "empty"]
  static values = { count: Number, frame: { type: String, default: "main" } }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      { received: (data) => this.#add(data) },
    )
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
  }

  countValueChanged() {
    if (!this.hasBadgeTarget) return

    const count = this.countValue
    this.badgeTarget.textContent = count > 99 ? "99+" : count
    this.badgeTarget.style.display = count > 0 ? "" : "none"
  }

  // Clicking a row navigates to its target (via Turbo) and the server marks it
  // read; decrement locally so the badge updates without waiting for a reload.
  markReadOptimistic(event) {
    const row = event.currentTarget
    if (row.dataset.read === "true") return

    row.dataset.read = "true"
    this.#markRowRead(row)
    if (this.countValue > 0) this.countValue -= 1
  }

  markAllRead() {
    fetch("/notifications/read_all", {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.#csrfToken(), "Accept": "text/html" },
      credentials: "same-origin",
    }).catch(() => {})

    this.countValue = 0
    if (this.hasListTarget) {
      this.listTarget.querySelectorAll("[data-notification-id]").forEach((row) => {
        row.dataset.read = "true"
        this.#markRowRead(row)
      })
    }
  }

  // ── private ────────────────────────────────────────────────────────────────

  #add(data) {
    if (!this.hasListTarget) return
    if (this.hasEmptyTarget) this.emptyTarget.classList.add("hidden")

    this.listTarget.insertAdjacentElement("afterbegin", this.#buildRow(data))
    this.countValue += 1
  }

  #buildRow(data) {
    const link = document.createElement("a")
    link.href = `/notifications/${data.id}/read`
    link.dataset.turboFrame = this.frameValue
    link.dataset.turboMethod = "patch"
    link.dataset.action = "click->notifications#markReadOptimistic"
    link.dataset.notificationId = data.id
    link.dataset.read = data.read ? "true" : "false"
    link.className =
      "flex items-start gap-2.5 px-4 py-3 text-sm transition-colors hover:bg-zinc-100 dark:hover:bg-zinc-800" +
      (data.read ? "" : " bg-brand-50/60 dark:bg-brand-500/10")

    const dot = document.createElement("span")
    dot.className = `mt-1.5 h-2 w-2 shrink-0 rounded-full ${data.read ? "bg-transparent" : "bg-brand-500"}`
    dot.setAttribute("aria-hidden", "true")

    const body = document.createElement("span")
    body.className = "min-w-0 flex-1"

    const actor = document.createElement("span")
    actor.className = "block truncate font-medium text-base-color"

    let lead = data.actor_label || "Someone"
    let captionText = ""
    switch (data.kind) {
      case "user_mentioned":
        captionText = "mentioned you"
        break
      case "invitation_accepted":
        captionText = "accepted your invitation"
        break
      case "project_membership_created":
        lead = `You were added to ${data.body_preview || "a project"}`
        break
      default:
        captionText = "sent a message"
    }

    actor.textContent = lead
    if (captionText) {
      const caption = document.createElement("span")
      caption.className = "font-normal text-muted-color"
      caption.textContent = ` ${captionText}`
      actor.appendChild(caption)
    }
    body.appendChild(actor)

    // The project name is already shown in the lead, so skip the preview line.
    if (data.body_preview && data.kind !== "project_membership_created") {
      const preview = document.createElement("span")
      preview.className = "block truncate text-xs text-muted-color"
      preview.textContent = data.body_preview
      body.appendChild(preview)
    }

    const time = document.createElement("span")
    time.className = "block text-xs text-muted-color"
    time.textContent = "just now"
    body.appendChild(time)

    link.appendChild(dot)
    link.appendChild(body)
    return link
  }

  #markRowRead(row) {
    row.classList.remove("bg-brand-50/60", "dark:bg-brand-500/10")
    const dot = row.querySelector("span[aria-hidden]")
    if (dot) dot.classList.replace("bg-brand-500", "bg-transparent")
  }

  #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
