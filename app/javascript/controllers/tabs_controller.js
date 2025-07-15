import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]
  static values = { defaultTab: String }

  connect() {
    // Set the default active tab on load
    const defaultTab = this.defaultTabValue || "review-detail"
    this.showTab(defaultTab)
  }

  switchTab(event) {
    const tabName = event.currentTarget.dataset.tabName
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabName === tabName
      this.updateTabStyles(tab, isActive)
    })

    // Update content panels
    this.contentTargets.forEach(content => {
      const isActive = content.dataset.tabName === tabName
      content.classList.toggle("hidden", !isActive)
    })
  }

  updateTabStyles(tab, isActive) {
    const svg = tab.querySelector('svg')
    
    if (isActive) {
      // Active tab styles
      tab.classList.remove("text-gray-500", "border-transparent")
      tab.classList.add("text-indigo-600", "border-indigo-500")
      if (svg) {
        svg.classList.remove("text-gray-400")
        svg.classList.add("text-indigo-500")
      }
    } else {
      // Inactive tab styles
      tab.classList.remove("text-indigo-600", "border-indigo-500")
      tab.classList.add("text-gray-500", "border-transparent")
      if (svg) {
        svg.classList.remove("text-indigo-500")
        svg.classList.add("text-gray-400")
      }
    }
  }
} 