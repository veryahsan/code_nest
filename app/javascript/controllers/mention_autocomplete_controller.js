import { Controller } from "@hotwired/stimulus"

// Typeahead for @mentions on the message composer. Reads the conversation's
// participant handles (embedded as JSON by the server) and, when the user is
// typing an @token, shows a filtered dropdown. Selecting an entry inserts the
// canonical @handle so the server-side parser resolves it unambiguously.
//
// The composer is a Trix editor (rich contenteditable), so token detection and
// insertion go through the Trix editor API (getSelectedRange / getDocument /
// setSelectedRange / insertString) rather than input value/caret manipulation.
//
// Shares the root element with the conversation controller; it only owns the
// input (trix-editor)/menu/participants targets and never touches message rendering.
export default class extends Controller {
  static targets = ["input", "menu", "participants"]

  // Token currently being typed: /(start-of-string or space)@partial/ at caret.
  static TOKEN_PATTERN = /(?:^|\s)@([a-z0-9_]*)$/i

  connect() {
    this.participants = this.#loadParticipants()
    this.matches = []
    this.activeIndex = -1
    this.tokenStart = null
  }

  disconnect() {
    this.#close()
  }

  onInput() {
    const editor = this.#editor
    if (!editor) return this.#close()

    const caret = editor.getSelectedRange()[1]
    const before = editor.getDocument().toString().slice(0, caret)
    const match = before.match(this.constructor.TOKEN_PATTERN)

    if (!match) return this.#close()

    const query = match[1].toLowerCase()
    this.tokenStart = caret - match[1].length - 1 // index of the '@'
    this.matches = this.#filter(query)

    if (this.matches.length === 0) return this.#close()

    this.activeIndex = 0
    this.#render()
  }

  onKeydown(event) {
    if (!this.#isOpen) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.#move(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.#move(-1)
        break
      case "Enter":
      case "Tab":
        event.preventDefault()
        this.#choose(this.activeIndex)
        break
      case "Escape":
        event.preventDefault()
        this.#close()
        break
    }
  }

  // ── private ────────────────────────────────────────────────────────────────

  get #editor() {
    return this.hasInputTarget ? this.inputTarget.editor : null
  }

  get #isOpen() {
    return this.hasMenuTarget && !this.menuTarget.classList.contains("hidden")
  }

  #loadParticipants() {
    if (!this.hasParticipantsTarget) return []
    try {
      return JSON.parse(this.participantsTarget.textContent || "[]")
    } catch {
      return []
    }
  }

  #filter(query) {
    const matches = this.participants.filter((p) => {
      const handle = (p.handle || "").toLowerCase()
      const label = (p.label || "").toLowerCase()
      return handle.startsWith(query) || label.includes(query)
    })
    return matches.slice(0, 8)
  }

  #render() {
    this.menuTarget.replaceChildren()

    this.matches.forEach((participant, index) => {
      const item = document.createElement("li")
      item.dataset.index = index
      item.className =
        "flex cursor-pointer items-center gap-2 px-3 py-1.5 text-sm " +
        (index === this.activeIndex ? "bg-zinc-100 dark:bg-zinc-800" : "")

      const handle = document.createElement("span")
      handle.className = "font-medium text-base-color"
      handle.textContent = `@${participant.handle}`

      const label = document.createElement("span")
      label.className = "truncate text-xs text-muted-color"
      label.textContent = participant.label || ""

      item.appendChild(handle)
      item.appendChild(label)

      // mousedown (not click) so selection runs before the editor loses focus.
      item.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.#choose(index)
      })

      this.menuTarget.appendChild(item)
    })

    this.menuTarget.classList.remove("hidden")
  }

  #move(delta) {
    const count = this.matches.length
    this.activeIndex = (this.activeIndex + delta + count) % count
    this.#render()
  }

  #choose(index) {
    const participant = this.matches[index]
    const editor = this.#editor
    if (!participant || this.tokenStart === null || !editor) return this.#close()

    const caret = editor.getSelectedRange()[1]
    editor.setSelectedRange([this.tokenStart, caret])
    editor.insertString(`@${participant.handle} `)
    this.inputTarget.focus()

    this.#close()
  }

  #close() {
    this.matches = []
    this.activeIndex = -1
    this.tokenStart = null
    if (this.hasMenuTarget) {
      this.menuTarget.replaceChildren()
      this.menuTarget.classList.add("hidden")
    }
  }
}
