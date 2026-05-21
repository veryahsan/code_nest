import { Controller } from "@hotwired/stimulus"

/**
 * Keeps document.title in sync when pages load inside the main Turbo Frame.
 */
export default class extends Controller {
  static values = { title: String }

  connect() {
    if (this.hasTitleValue) document.title = this.titleValue
  }
}
