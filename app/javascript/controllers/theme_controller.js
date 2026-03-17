import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY_MODE = "mtracker_theme_mode"
const DEFAULT_MODE = "light"

export default class extends Controller {
  static targets = ["toggleOption"]

  connect() {
    const lock = this.element.dataset.themeLock
    if (lock) {
      this.applyTheme(lock)
      return
    }
    const mode = localStorage.getItem(STORAGE_KEY_MODE) || DEFAULT_MODE
    this.applyTheme(mode)

    if (this.hasToggleOptionTargets) {
      this.toggleOptionTargets.forEach((el) => {
        el.classList.toggle("active", el.dataset.themeMode === mode)
        el.setAttribute("aria-pressed", el.dataset.themeMode === mode)
      })
    }
  }

  setMode(event) {
    const mode = event.currentTarget.dataset.themeMode
    if (!mode) return
    localStorage.setItem(STORAGE_KEY_MODE, mode)
    this.applyTheme(mode)
    if (this.hasToggleOptionTargets) {
      this.toggleOptionTargets.forEach((el) => {
        el.classList.toggle("active", el.dataset.themeMode === mode)
        el.setAttribute("aria-pressed", el.dataset.themeMode === mode)
      })
    }
  }

  applyTheme(mode) {
    document.documentElement.setAttribute("data-theme", mode)
  }
}
