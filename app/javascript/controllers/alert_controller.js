import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.element.remove()
    }, 15000) // 15 seconds
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
} 