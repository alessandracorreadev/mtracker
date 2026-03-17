import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY_MODE = "mtracker_theme_mode"
const DEFAULT_MODE = "light"

export default class extends Controller {
  static targets = ["toggleOption", "sidebarIcon"]

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
    this.updateSidebarIcon(mode)
  }

  toggle() {
    const current = localStorage.getItem(STORAGE_KEY_MODE) || DEFAULT_MODE
    const next = current === "light" ? "dark" : "light"
    localStorage.setItem(STORAGE_KEY_MODE, next)
    this.applyTheme(next)
    if (this.hasToggleOptionTargets) {
      this.toggleOptionTargets.forEach((el) => {
        el.classList.toggle("active", el.dataset.themeMode === next)
        el.setAttribute("aria-pressed", el.dataset.themeMode === next)
      })
    }
    this.updateSidebarIcon(next)
  }

  updateSidebarIcon(mode) {
    if (!this.hasSidebarIconTarget) return
    const icon = this.sidebarIconTarget
    icon.classList.remove("fa-toggle-on", "fa-toggle-off")
    icon.classList.add(mode === "dark" ? "fa-toggle-on" : "fa-toggle-off")
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
    this.updateSidebarIcon(mode)
  }

  applyTheme(mode) {
    document.documentElement.setAttribute("data-theme", mode)
    const meta = document.getElementById("theme-color-meta")
    if (meta) meta.setAttribute("content", mode === "dark" ? "#343a40" : "#ffffff")
  }
}
