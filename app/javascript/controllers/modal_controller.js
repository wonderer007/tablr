import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Make this controller accessible globally for JavaScript functions
    window.termsModalController = this
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    
    // Focus on the modal for accessibility
    this.modalTarget.focus()
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }
}
