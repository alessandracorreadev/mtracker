import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "toggleButton"]

  connect() {
    this.closeOnLink = this.closeOnLink.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  toggle() {
    const isOpen = this.sidebarTarget.classList.toggle("open")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.toggle("open", isOpen)
    }
    document.body.classList.toggle("sidebar-open", isOpen)
    this.syncToggleA11y(isOpen)

    if (isOpen) {
      document.addEventListener("click", this.closeOnLink, true)
      document.addEventListener("keydown", this.closeOnEscape)
    } else {
      document.removeEventListener("click", this.closeOnLink, true)
      document.removeEventListener("keydown", this.closeOnEscape)
    }
  }

  close() {
    this.sidebarTarget.classList.remove("open")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("open")
    }
    document.body.classList.remove("sidebar-open")
    this.syncToggleA11y(false)
    document.removeEventListener("click", this.closeOnLink, true)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  syncToggleA11y(isOpen) {
    if (!this.hasToggleButtonTarget) return
    this.toggleButtonTarget.setAttribute("aria-expanded", isOpen)
    this.toggleButtonTarget.setAttribute("aria-label", isOpen ? "Fechar menu" : "Abrir menu")
  }

  closeOnLink(event) {
    if (this.sidebarTarget.contains(event.target) && event.target.closest("a[href]")) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
