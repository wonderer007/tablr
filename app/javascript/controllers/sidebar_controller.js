import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileSidebar", "backdrop"]

  connect() {
    // Close sidebar when clicking outside
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
    
    // Close sidebar on escape key
    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.handleEscape)
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('click', this.handleClickOutside)
    document.removeEventListener('keydown', this.handleEscape)
  }

  open() {
    this.mobileSidebarTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden' // Prevent background scrolling
  }

  close() {
    this.mobileSidebarTarget.classList.add('hidden')
    document.body.style.overflow = '' // Restore scrolling
  }

  toggle() {
    if (this.mobileSidebarTarget.classList.contains('hidden')) {
      this.open()
    } else {
      this.close()
    }
  }

  handleClickOutside(event) {
    // Don't close if clicking on the sidebar content itself
    if (this.mobileSidebarTarget.contains(event.target)) {
      return
    }
    
    // Close sidebar if clicking outside or on backdrop
    this.close()
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
} 