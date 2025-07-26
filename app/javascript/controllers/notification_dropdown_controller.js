import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener('click', this.handleClickOutside)
  }

  toggle() {
    const isExpanded = this.buttonTarget.getAttribute('aria-expanded') === 'true'
    this.setExpanded(!isExpanded)
  }

  setExpanded(expanded) {
    this.buttonTarget.setAttribute('aria-expanded', expanded.toString())
    if (expanded) {
      this.menuTarget.classList.remove('hidden')
    } else {
      this.menuTarget.classList.add('hidden')
    }
  }

  handleClickOutside(event) {
    if (this.element.contains(event.target)) {
      return
    }
    this.setExpanded(false)
  }
} 