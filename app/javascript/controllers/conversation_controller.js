import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Subscribes to a single ConversationChannel and renders messages pushed
// over the Redis-backed Action Cable stream. New messages are composed in the
// Lexxy editor and sent back over the same channel (no full page round-trip).
//
// Message bodies are rendered to HTML on the server (Action Text resolves
// @mention attachments to the employees/_employee partial), so the client only
// injects that trusted HTML and flags the viewer's own mentions per-viewer.
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

    // Enter-to-send: intercept in the capture phase so we win over Lexical's own
    // Enter handler. Enter always sends; Shift+Enter adds a new line (a new
    // bullet when inside a list). When the @mention menu is open we bow out so
    // Enter selects the highlighted suggestion instead.
    if (this.hasInputTarget) {
      this.onEditorKeydown = this.onKeydown.bind(this)
      this.inputTarget.addEventListener("keydown", this.onEditorKeydown, true)
    }

    // Lexxy applies a list per block, so a multi-line paragraph (lines joined by
    // soft <br> breaks) collapses into a single bullet. Intercept the list
    // buttons and split the caret's paragraph so each line from the cursor down
    // becomes its own list item, leaving earlier lines as a paragraph.
    if (this.hasInputTarget) {
      this.onListButtonClick = this.#onListButtonClick.bind(this)
      this.inputTarget.addEventListener("click", this.onListButtonClick, true)
    }

    this.#applySelfMentions(this.listTarget)
    this.scrollToBottom()
  }

  #onListButtonClick(event) {
    const btn = event.target.closest('button[name="unordered-list"], button[name="ordered-list"]')
    if (!btn) return

    const ed = this.inputTarget
    const ordered = btn.getAttribute("name") === "ordered-list"

    const newValue = this.#listFromCursor(ed, ordered)
    if (newValue != null) {
      event.preventDefault()
      event.stopImmediatePropagation()
      ed.value = newValue
      ed.focus()
    }
  }

  // Builds new editor HTML that turns the caret's line (and the lines below it)
  // within the current paragraph into list items. Returns null when the default
  // Lexxy behavior should be used (caret not in a multi-line paragraph).
  #listFromCursor(ed, ordered) {
    const liveContent = ed.querySelector(".lexxy-editor__content")
    const selection = window.getSelection()
    if (!liveContent || !selection || selection.rangeCount === 0) return null

    const anchorNode = selection.anchorNode
    if (!anchorNode || !liveContent.contains(anchorNode)) return null

    // The top-level block (direct child of the content root) holding the caret.
    let liveBlock = anchorNode.nodeType === 1 ? anchorNode : anchorNode.parentElement
    while (liveBlock && liveBlock.parentElement !== liveContent) {
      liveBlock = liveBlock.parentElement
    }
    if (!liveBlock || liveBlock.tagName !== "P") return null

    const liveBreaks = Array.from(liveBlock.querySelectorAll("br"))
    if (liveBreaks.length === 0) return null // single line: let Lexxy handle it

    // Which line the caret sits on = number of <br>s that precede it.
    const lineIndex = liveBreaks.filter(
      (br) => br.compareDocumentPosition(anchorNode) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).length

    const blockIndex = Array.from(liveContent.children).indexOf(liveBlock)
    if (blockIndex < 0) return null

    // Operate on the canonical serialized value so @mention attachments survive.
    const doc = new DOMParser().parseFromString(ed.value || "", "text/html")
    const valueBlock = doc.body.children[blockIndex]
    if (!valueBlock || valueBlock.tagName !== "P") return null

    const lines = this.#splitNodesByBreak(doc, Array.from(valueBlock.childNodes))
    if (lineIndex >= lines.length) return null

    const keep = lines.slice(0, lineIndex)
    let listLines = lines.slice(lineIndex)
    // Drop a single trailing empty line (e.g. caret left a dangling <br>).
    if (listLines.length > 1 && listLines[listLines.length - 1].trim() === "") {
      listLines = listLines.slice(0, -1)
    }
    if (listLines.length === 0) return null

    const tag = ordered ? "ol" : "ul"
    const items = listLines.map((html) => `<li>${html || "<br>"}</li>`).join("")
    const replacement = (keep.length ? `<p>${keep.join("<br>")}</p>` : "") + `<${tag}>${items}</${tag}>`

    const before = Array.from(doc.body.children).slice(0, blockIndex).map((el) => el.outerHTML).join("")
    const after = Array.from(doc.body.children).slice(blockIndex + 1).map((el) => el.outerHTML).join("")
    return before + replacement + after
  }

  // Splits a list of nodes into per-line HTML strings, breaking on <br> and
  // serializing each segment (preserving element nodes like attachments).
  #splitNodesByBreak(doc, nodes) {
    const lines = []
    let current = doc.createElement("div")
    for (const node of nodes) {
      if (node.nodeType === 1 && node.tagName === "BR") {
        lines.push(current.innerHTML)
        current = doc.createElement("div")
      } else {
        current.appendChild(node.cloneNode(true))
      }
    }
    lines.push(current.innerHTML)
    return lines
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
    if (this.hasInputTarget && this.onEditorKeydown) {
      this.inputTarget.removeEventListener("keydown", this.onEditorKeydown, true)
    }
    if (this.hasInputTarget && this.onListButtonClick) {
      this.inputTarget.removeEventListener("click", this.onListButtonClick, true)
    }
    clearTimeout(this.readTimer)
  }

  submit(event) {
    event.preventDefault()
    if (!this.hasInputTarget) return

    const editor = this.inputTarget
    // The Lexxy editor stringifies to its plain text; skip empty sends.
    if (editor.toString().trim() === "") return

    this.subscription.perform("speak", { body_text: editor.value })

    editor.value = ""
    editor.focus()
  }

  // Bound as a capture-phase listener on the Lexxy editor (see connect). Enter
  // always sends; Shift+Enter adds a new line (a new bullet inside a list). The
  // mention menu takes Enter to pick a suggestion.
  onKeydown(event) {
    if (event.key !== "Enter") return
    if (document.querySelector(".lexxy-prompt-menu--visible")) return

    if (event.shiftKey) {
      // New line. Inside a list, turn the soft break into a new bullet by
      // re-issuing a plain Enter, which Lexical converts to a new list item.
      // Elsewhere, fall through to Lexxy's default soft line break.
      if (this.#caretElement()?.closest("li") && !this.insertingListItem) {
        event.preventDefault()
        event.stopImmediatePropagation()
        this.insertingListItem = true
        event.target.dispatchEvent(
          new KeyboardEvent("keydown", { key: "Enter", code: "Enter", bubbles: true, cancelable: true }),
        )
        this.insertingListItem = false
      }
      return
    }

    // The re-dispatched Enter above must build the list item, not send.
    if (this.insertingListItem) return

    // Plain Enter sends in every context.
    event.preventDefault()
    event.stopImmediatePropagation()
    this.submit(event)
  }

  // The element holding the text caret, or null when there is no selection.
  #caretElement() {
    const anchor = window.getSelection()?.anchorNode
    return anchor && anchor.nodeType === 1 ? anchor : anchor?.parentElement
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
      ? "max-w-[85%] rounded-2xl rounded-br-sm bg-brand-600 px-3 py-2 text-sm text-white"
      : "max-w-[85%] rounded-2xl rounded-bl-sm bg-surface-raised border border-surface px-3 py-2 text-sm text-base-color"
    this.#renderBody(bubble, message)

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

  // Render a message bubble. Rich messages carry server-rendered, sanitized
  // HTML (with @mentions already resolved to pills), so we inject it directly;
  // plain messages fall back to their text body.
  #renderBody(el, message) {
    if (message.body_html) {
      el.innerHTML = message.body_html
      this.#applySelfMentions(el)
    } else {
      el.textContent = message.body || ""
    }
  }

  // Highlight the viewer's own @mentions. A shared server broadcast can't bake
  // in per-viewer styling, so each client flags the mentions that point at its
  // own user record (matched by data-mention-user-id).
  #applySelfMentions(root) {
    const id = this.userIdValue
    if (!root || !id) return

    root
      .querySelectorAll(`.mention[data-mention-user-id="${id}"]`)
      .forEach((node) => node.classList.add("is-self"))
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
