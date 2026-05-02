/**
 * Theme Controller — Dark / Light mode toggle.
 *
 * Place on the <html> element:
 *   <html data-controller="theme" ...>
 *
 * To toggle from anywhere in the page:
 *   <button data-action="click->theme#toggle">Toggle theme</button>
 *
 * Reads / writes "cn-theme" in localStorage so the preference persists across
 * page loads. On first visit defaults to the OS colour-scheme preference.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { default: { type: String, default: "system" } }

  connect() {
    this.applyStoredTheme()
  }

  toggle() {
    const current = this.#resolvedTheme()
    this.#setTheme(current === "dark" ? "light" : "dark")
  }

  setLight() { this.#setTheme("light") }
  setDark()  { this.#setTheme("dark") }

  applyStoredTheme() {
    const stored = localStorage.getItem("cn-theme") || this.defaultValue
    this.#applyTheme(stored)
  }

  get isDark() {
    return document.documentElement.classList.contains("dark")
  }

  // ── private ────────────────────────────────────────────────────────────────

  #setTheme(value) {
    localStorage.setItem("cn-theme", value)
    this.#applyTheme(value)
  }

  #applyTheme(value) {
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const dark = value === "dark" || (value === "system" && prefersDark)
    document.documentElement.classList.toggle("dark", dark)
    document.documentElement.setAttribute("data-theme", dark ? "dark" : "light")

    // Let any theme-toggle buttons update their icons
    this.dispatch("changed", { detail: { theme: dark ? "dark" : "light" } })
  }

  #resolvedTheme() {
    return this.isDark ? "dark" : "light"
  }
}
