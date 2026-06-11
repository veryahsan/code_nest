import { Controller } from "@hotwired/stimulus"

/**
 * Tabs Controller — client-side tabbed panels (no navigation).
 *
 * Markup pattern:
 *   <div data-controller="tabs"
 *        data-tabs-active-value="text-brand-600 border-brand-600"
 *        data-tabs-inactive-value="text-muted-color border-transparent hover:text-base-color">
 *     <nav>
 *       <button data-tabs-target="tab" data-tab-name="overview"
 *               data-action="click->tabs#select">Overview</button>
 *       ...
 *     </nav>
 *     <div data-tabs-target="panel" data-tab-panel="overview">...</div>
 *     ...
 *   </div>
 *
 * The first tab (or one marked data-tab-default) is shown on connect.
 */
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: String, inactive: String }

  connect() {
    const initial =
      this.tabTargets.find((t) => t.dataset.tabDefault === "true") ||
      this.tabTargets[0]
    if (initial) this.#activate(initial.dataset.tabName)
  }

  select(event) {
    const name = event.currentTarget.dataset.tabName
    if (name) this.#activate(name)
  }

  #activate(name) {
    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.tabName === name
      tab.setAttribute("aria-selected", isActive ? "true" : "false")
      this.#applyClasses(tab, isActive)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.tabPanel !== name)
    })
  }

  #applyClasses(tab, isActive) {
    const active = this.#tokens(this.activeValue)
    const inactive = this.#tokens(this.inactiveValue)
    tab.classList.remove(...active, ...inactive)
    tab.classList.add(...(isActive ? active : inactive))
  }

  #tokens(value) {
    return (value || "").split(/\s+/).filter(Boolean)
  }
}
