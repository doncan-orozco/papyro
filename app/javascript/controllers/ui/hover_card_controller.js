import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset } from "@floating-ui/dom"

/**
 * Hover Card Stimulus Controller
 * 
 * Manages hover card with show/hide on hover or focus, smart positioning
 * Uses Floating UI for dynamic positioning
 * 
 * Usage:
 *   <div data-controller="ui--hover-card" data-ui--hover-card-open-value="false">
 *     <button data-ui--hover-card-target="trigger" 
 *             data-action="mouseenter->ui--hover-card#show mouseleave->ui--hover-card#hide">
 *       Hover me
 *     </button>
 *     <div data-ui--hover-card-target="content" hidden>
 *       Content shown on hover...
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether hover card is visible
 *   - placement (String): Preferred position (default: "top")
 *   - offset (Number): Distance from trigger in pixels (default: 4)
 *   - delay (Number): Milliseconds before showing (default: 200)
 * 
 * Actions:
 *   - show: Show the hover card
 *   - hide: Hide the hover card
 * 
 * Events dispatched:
 *   - ui:hover-card:opened
 *   - ui:hover-card:closed
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false },
    placement: { type: String, default: "top" },
    offset: { type: Number, default: 4 },
    delay: { type: Number, default: 200 }
  }

  static targets = ["trigger", "content"]

  connect() {
    console.log('🎯 Hover Card controller connected', this.element)
    this.showTimeout = null
    this.hideTimeout = null
    this.cleanupAutoUpdate = null
    
    // Setup content
    if (this.hasContentTarget) {
      this.contentTarget.hidden = true
      this.contentTarget.style.position = 'absolute'
      this.contentTarget.style.zIndex = '1000'
    }
  }

  disconnect() {
    this.clearTimeouts()
    this.stopAutoUpdate()
  }

  /**
   * Show the hover card
   * @param {Event} event - Mouse/focus event
   */
  show(event) {
    console.log('🎯 Hover Card show')
    event?.preventDefault()
    
    // Cancel any pending hide
    this.clearHideTimeout()
    
    // Delay showing
    this.showTimeout = setTimeout(() => {
      this.openValue = true
    }, this.delayValue)
  }

  /**
   * Hide the hover card
   * @param {Event} event - Mouse/blur event
   */
  hide(event) {
    console.log('🎯 Hover Card hide')
    event?.preventDefault()
    
    // Cancel any pending show
    this.clearShowTimeout()
    
    // Immediately hide on mouse leave
    this.openValue = false
  }

  /**
   * Update when open value changes
   */
  async openValueChanged() {
    if (this.openValue) {
      await this.openCard()
    } else {
      this.closeCard()
    }
  }

  /**
   * Open the hover card
   */
  async openCard() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    // Show content
    this.contentTarget.hidden = false
    this.contentTarget.style.visibility = 'visible'
    this.contentTarget.style.opacity = '0'
    
    // Position card
    await this.updatePosition()
    
    // Fade in
    requestAnimationFrame(() => {
      this.contentTarget.style.opacity = '1'
    })
    
    // Start auto-updating position
    this.startAutoUpdate()
    
    this.dispatchStateChange("ui:hover-card:opened")
  }

  /**
   * Close the hover card
   */
  closeCard() {
    if (!this.hasContentTarget) return

    // Hide content
    this.contentTarget.style.opacity = '0'
    this.contentTarget.style.visibility = 'hidden'
    
    setTimeout(() => {
      if (this.hasContentTarget) {
        this.contentTarget.hidden = true
      }
    }, 150)
    
    // Stop auto-updating position
    this.stopAutoUpdate()
    
    this.dispatchStateChange("ui:hover-card:closed")
  }

  /**
   * Update hover card position using Floating UI
   */
  async updatePosition() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    const { x, y } = await computePosition(
      this.triggerTarget,
      this.contentTarget,
      {
        placement: this.placementValue,
        middleware: [
          flip(),
          shift({ padding: 8 }),
          offset(this.offsetValue)
        ]
      }
    )

    this.contentTarget.style.left = `${x}px`
    this.contentTarget.style.top = `${y}px`
  }

  /**
   * Start auto-updating position during scroll/resize
   */
  startAutoUpdate() {
    if (this.cleanupAutoUpdate) return

    const update = async () => {
      await this.updatePosition()
    }

    window.addEventListener('scroll', update, true)
    window.addEventListener('resize', update)

    this.cleanupAutoUpdate = () => {
      window.removeEventListener('scroll', update, true)
      window.removeEventListener('resize', update)
    }
  }

  /**
   * Stop auto-updating position
   */
  stopAutoUpdate() {
    if (this.cleanupAutoUpdate) {
      this.cleanupAutoUpdate()
      this.cleanupAutoUpdate = null
    }
  }

  /**
   * Clear show timeout
   */
  clearShowTimeout() {
    if (this.showTimeout) {
      clearTimeout(this.showTimeout)
      this.showTimeout = null
    }
  }

  /**
   * Clear hide timeout
   */
  clearHideTimeout() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
      this.hideTimeout = null
    }
  }

  /**
   * Clear all timeouts
   */
  clearTimeouts() {
    this.clearShowTimeout()
    this.clearHideTimeout()
  }
}
