import BaseController from "controllers/ui/base_controller"

/**
 * Carousel Stimulus Controller
 * 
 * Manages carousel/slide component with previous/next navigation and keyboard support
 * Supports looping and auto-play
 * 
 * Usage:
 *   <div data-controller="ui--carousel" data-ui--carousel-auto-play-value="false">
 *     <div data-ui--carousel-target="viewport">
 *       <div data-ui--carousel-target="item">Slide 1</div>
 *       <div data-ui--carousel-target="item">Slide 2</div>
 *       <div data-ui--carousel-target="item">Slide 3</div>
 *     </div>
 *     <button data-action="click->ui--carousel#previous">Previous</button>
 *     <button data-action="click->ui--carousel#next">Next</button>
 *     <div data-ui--carousel-target="controls">
 *       <button data-action="click->ui--carousel#goToSlide" data-slide-index="0">1</button>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - currentIndex (Number): Current slide index (default: 0)
 *   - loop (Boolean): Loop to first slide after last (default: true)
 *   - autoPlay (Boolean): Auto-advance slides (default: false)
 *   - autoPlayInterval (Number): Milliseconds between slides (default: 5000)
 * 
 * Actions:
 *   - next: Go to next slide
 *   - previous: Go to previous slide
 *   - goToSlide: Go to specific slide by index
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:carousel:changed - { index: number, total: number }
 */
export default class extends BaseController {
  static values = {
    currentIndex: { type: Number, default: 0 },
    loop: { type: Boolean, default: true },
    autoPlay: { type: Boolean, default: false },
    autoPlayInterval: { type: Number, default: 5000 }
  }

  static targets = ["viewport", "item", "controls"]

  connect() {
    this.autoPlayTimeout = null
    
    // Setup ARIA attributes
    this.element.setAttribute('role', 'region')
    this.element.setAttribute('aria-roledescription', 'carousel')
    this.element.setAttribute('aria-live', 'polite')
    
    // Update initial state
    this.updateCarousel()
    
    // Start auto-play if enabled
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }
  }

  disconnect() {
    this.stopAutoPlay()
  }

  /**
   * Go to next slide
   * @param {Event} event - Click event
   */
  next(event) {
    event?.preventDefault()
    
    const nextIndex = this.currentIndexValue + 1
    
    if (nextIndex >= this.itemTargets.length) {
      this.currentIndexValue = this.loopValue ? 0 : this.itemTargets.length - 1
    } else {
      this.currentIndexValue = nextIndex
    }
    
    // Reset auto-play timer
    if (this.autoPlayValue) {
      this.stopAutoPlay()
      this.startAutoPlay()
    }
  }

  /**
   * Go to previous slide
   * @param {Event} event - Click event
   */
  previous(event) {
    event?.preventDefault()
    
    const prevIndex = this.currentIndexValue - 1
    
    if (prevIndex < 0) {
      this.currentIndexValue = this.loopValue ? this.itemTargets.length - 1 : 0
    } else {
      this.currentIndexValue = prevIndex
    }
    
    // Reset auto-play timer
    if (this.autoPlayValue) {
      this.stopAutoPlay()
      this.startAutoPlay()
    }
  }

  /**
   * Go to specific slide by index
   * @param {Event} event - Click event
   */
  goToSlide(event) {
    event?.preventDefault()
    
    const index = parseInt(event.currentTarget.dataset.slideIndex, 10)
    if (!isNaN(index) && index >= 0 && index < this.itemTargets.length) {
      this.currentIndexValue = index
      
      // Reset auto-play timer
      if (this.autoPlayValue) {
        this.stopAutoPlay()
        this.startAutoPlay()
      }
    }
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    switch (event.key) {
      case 'ArrowRight':
      case 'End':
        event.preventDefault()
        this.next()
        break
      case 'ArrowLeft':
      case 'Home':
        event.preventDefault()
        this.previous()
        break
    }
  }

  /**
   * Update carousel state
   */
  currentIndexValueChanged() {
    this.updateCarousel()
  }

  /**
   * Update carousel display and accessibility
   */
  updateCarousel() {
    const total = this.itemTargets.length
    if (total === 0) return

    // Update item visibility
    this.itemTargets.forEach((item, index) => {
      const isActive = index === this.currentIndexValue
      item.setAttribute('data-state', isActive ? 'active' : 'inactive')
      item.setAttribute('aria-hidden', !isActive)
      item.style.display = isActive ? 'block' : 'none'
    })

    // Update control buttons if they exist
    if (this.hasControlsTarget) {
      const buttons = this.controlsTarget.querySelectorAll('button')
      buttons.forEach((button, index) => {
        const isActive = index === this.currentIndexValue
        button.setAttribute('data-state', isActive ? 'active' : 'inactive')
        button.setAttribute('aria-current', isActive ? 'page' : 'false')
      })
    }

    // Dispatch change event
    this.dispatchStateChange('ui:carousel:changed', {
      index: this.currentIndexValue,
      total
    })
  }

  /**
   * Start auto-play
   */
  startAutoPlay() {
    if (this.autoPlayTimeout) return

    this.autoPlayTimeout = setInterval(() => {
      this.next()
    }, this.autoPlayIntervalValue)
  }

  /**
   * Stop auto-play
   */
  stopAutoPlay() {
    if (this.autoPlayTimeout) {
      clearInterval(this.autoPlayTimeout)
      this.autoPlayTimeout = null
    }
  }

  /**
   * Handle auto-play value change
   */
  autoPlayValueChanged() {
    if (this.autoPlayValue) {
      this.startAutoPlay()
    } else {
      this.stopAutoPlay()
    }
  }
}
