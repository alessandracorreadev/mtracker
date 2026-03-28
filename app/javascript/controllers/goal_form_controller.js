import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "categoryWrapper", "categoryInput"]

  connect() {
    this.#applyCategoryLogic(this.typeSelectTarget.value)
  }

  onTypeChange(e) {
    this.#applyCategoryLogic(e.target.value)
  }

  #applyCategoryLogic(val) {
    if (val === "savings") {
      this.categoryWrapperTarget.classList.add("d-none")
      if (this.hasCategoryInputTarget) this.categoryInputTarget.value = ""
    } else {
      this.categoryWrapperTarget.classList.remove("d-none")
      if (this.hasCategoryInputTarget) {
        if (val === "expense") {
          this.categoryInputTarget.setAttribute("list", "expense-categories-datalist")
        } else if (val === "investment") {
          this.categoryInputTarget.setAttribute("list", "investment-categories-datalist")
        }
      }
    }
  }
}
