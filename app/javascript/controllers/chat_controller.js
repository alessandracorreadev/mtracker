import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "container", "input", "form", "submitBtn"]

  connect() {
    this.scrollToBottom()
    this.#setupForm()
    this.#observeMessages()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    const container = this.containerTarget
    container.scrollTop = container.scrollHeight
  }

  #setupForm() {
    const input = this.inputTarget
    const form = this.formTarget

    const freshInput = input.cloneNode(true)
    input.parentNode.replaceChild(freshInput, input)

    freshInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault()
        if (freshInput.value.trim() !== "") {
          this.#prepareSubmit()
          form.requestSubmit()
        }
      }
    })

    form.addEventListener("submit", (e) => {
      if (freshInput.value.trim() !== "") {
        this.#prepareSubmit()
      } else {
        e.preventDefault()
        freshInput.focus()
      }
    })

    freshInput.focus()
  }

  #prepareSubmit() {
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.innerHTML = "<i class='fa-solid fa-circle-notch fa-spin'></i>"
      this.submitBtnTarget.style.pointerEvents = "none"
    }
  }

  #observeMessages() {
    const messagesDiv = this.messagesTarget

    this.observer = new MutationObserver(() => {
      this.scrollToBottom()

      const lastMsg = messagesDiv.lastElementChild
      if (lastMsg && !lastMsg.querySelector(".typing-indicator")) {
        if (this.hasSubmitBtnTarget) {
          this.submitBtnTarget.innerHTML = "<i class='fa-solid fa-paper-plane' style='margin-left:-2px'></i>"
          this.submitBtnTarget.style.pointerEvents = "auto"
        }
      }
    })

    this.observer.observe(messagesDiv, { childList: true, subtree: true })
  }
}
