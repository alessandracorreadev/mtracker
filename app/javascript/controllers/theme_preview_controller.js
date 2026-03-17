import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "input"]

  connect() {
    this.updatePreview()
  }

  updatePreview() {
    if (this.hasPreviewTarget && this.hasInputTarget) {
      this.previewTarget.style.backgroundColor = this.inputTarget.value
    }
  }

  change() {
    this.updatePreview()
  }
}
