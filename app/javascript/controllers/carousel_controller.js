import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "dot", "slide"]
  static values = { autoplay: { type: Boolean, default: true }, interval: { type: Number, default: 5000 } }

  connect() {
    this.currentIndex = 0
    this.totalSlides = this.slideTargets.length
    
    // Start autoplay if enabled
    if (this.autoplayValue) {
      this.startAutoplay()
    }
    
    // Pause autoplay on hover
    this.element.addEventListener('mouseenter', () => this.pauseAutoplay())
    this.element.addEventListener('mouseleave', () => this.startAutoplay())
  }

  disconnect() {
    this.pauseAutoplay()
  }

  previous() {
    this.currentIndex = (this.currentIndex - 1 + this.totalSlides) % this.totalSlides
    this.updateCarousel()
    this.restartAutoplay()
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.totalSlides
    this.updateCarousel()
    this.restartAutoplay()
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.slide)
    this.currentIndex = index
    this.updateCarousel()
    this.restartAutoplay()
  }

  updateCarousel() {
    // Update track position
    const translateX = -this.currentIndex * 100
    this.trackTarget.style.transform = `translateX(${translateX}%)`
    
    // Update dots
    this.dotTargets.forEach((dot, index) => {
      if (index === this.currentIndex) {
        dot.classList.remove('bg-gray-300', 'hover:bg-gray-400')
        dot.classList.add('bg-indigo-600')
      } else {
        dot.classList.remove('bg-indigo-600')
        dot.classList.add('bg-gray-300', 'hover:bg-gray-400')
      }
    })
  }

  startAutoplay() {
    if (this.autoplayValue && !this.autoplayTimer) {
      this.autoplayTimer = setInterval(() => {
        this.next()
      }, this.intervalValue)
    }
  }

  pauseAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer)
      this.autoplayTimer = null
    }
  }

  restartAutoplay() {
    this.pauseAutoplay()
    this.startAutoplay()
  }
}