import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Close dropdown when clicking outside
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }

  disconnect() {
    // Clean up event listener
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
    // Don't close if clicking on the button or menu
    if (this.element.contains(event.target)) {
      return
    }
    
    // Close dropdown if clicking outside
    this.setExpanded(false)
  }
} 