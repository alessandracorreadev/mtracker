import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    this.closeOnLink = this.closeOnLink.bind(this)
  }

  toggle() {
    this.sidebarTarget.classList.toggle("open")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.toggle("open")
    }
    document.body.classList.toggle("sidebar-open", this.sidebarTarget.classList.contains("open"))
    if (this.sidebarTarget.classList.contains("open")) {
      document.addEventListener("click", this.closeOnLink, true)
    } else {
      document.removeEventListener("click", this.closeOnLink, true)
    }
  }

  close() {
    this.sidebarTarget.classList.remove("open")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("open")
    }
    document.body.classList.remove("sidebar-open")
    document.removeEventListener("click", this.closeOnLink, true)
  }

  closeOnLink(event) {
    if (this.sidebarTarget.contains(event.target) && event.target.closest("a[href]")) {
      this.close()
    }
  }
}
