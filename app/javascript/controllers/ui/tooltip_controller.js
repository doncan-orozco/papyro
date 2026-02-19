import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset, arrow } from "@floating-ui/dom"

/**
 * Tooltip Stimulus Controller
 * 
 * Shows/hides tooltips on hover and focus with dynamic positioning
 * Uses Floating UI for smart positioning that avoids viewport edges
 * 
 * Usage:
 *   <div data-controller="ui--tooltip" data-ui--tooltip-delay-value="200">
 *     <div data-ui--tooltip-target="trigger" 
 *          data-action="mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide focus->ui--tooltip#show blur->ui--tooltip#hide">
 *       Hover me
 *     </div>
 *     <div data-ui--tooltip-target="content" hidden>
 *       Tooltip content
 *     </div>
 *   </div>
 * 
 * Values:
 *   - visible (Boolean): Whether tooltip is currently visible
 *   - delay (Number): Show delay in milliseconds (default: 200)
 *   - placement (String): Preferred position (default: "top")
 *   - offset (Number): Distance from trigger in pixels (default: 4)
 * 
 * Actions:
 *   - show: Show tooltip after delay
 *   - hide: Hide tooltip immediately
 * 
 * Events dispatched:
 *   - ui:tooltip:shown
 *   - ui:tooltip:hidden
 */
export default class extends BaseController {
  static values = {
    visible: { type: Boolean, default: false },
    delay: { type: Number, default: 200 },
    placement: { type: String, default: "top" },
    offset: { type: Number, default: 4 }
  }

  static targets = ["trigger", "content"]

  connect() {
    console.log('💬 Tooltip controller connected', this.element)
    this.showTimeout = null
    this.cleanupAutoUpdate = null
    
    // Hide content initially
    if (this.hasContentTarget) {
      this.contentTarget.hidden = true
      this.contentTarget.style.position = 'absolute'
      this.contentTarget.style.width = 'max-content'
    }
    
    // Listen for ESC key globally when visible
    this.handleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    this.clearShowTimeout()
    this.stopAutoUpdate()
    window.removeEventListener('keydown', this.handleEscape)
  }

  /**
   * Show tooltip after delay
   * @param {Event} event - Mouse or focus event
   */
  show(event) {
    // Clear any pending hide/show
    this.clearShowTimeout()
    
    // Show after delay
    this.showTimeout = setTimeout(() => {
      this.visibleValue = true
    }, this.delayValue)
  }

  /**
   * Hide tooltip immediately
   * @param {Event} event - Mouse or blur event
   */
  hide(event) {
    this.clearShowTimeout()
    this.visibleValue = false
  }

  /**
   * Handle ESC key to hide tooltip
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleEscape(event) {
    if (event.key === 'Escape' && this.visibleValue) {
      this.hide()
    }
  }

  /**
   * Update when visible value changes
   */
  async visibleValueChanged() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    if (this.visibleValue) {
      await this.showTooltip()
    } else {
      this.hideTooltip()
    }
  }

  /**
   * Show and position the tooltip
   */
  async showTooltip() {
    const content = this.contentTarget
    const trigger = this.triggerTarget
    
    // Show content
    content.hidden = false
    content.style.opacity = '0'
    
    // Set aria-describedby
    const tooltipId = content.id || this.generateTooltipId()
    content.id = tooltipId
    trigger.setAttribute('aria-describedby', tooltipId)
    
    // Compute position
    await this.updatePosition()
    
    // Fade in
    content.style.opacity = '1'
    
    // Start auto-updating position
    this.startAutoUpdate()
    
    // Listen for ESC key
    window.addEventListener('keydown', this.handleEscape)
    
    this.dispatchStateChange("ui:tooltip:shown")
  }

  /**
   * Hide the tooltip
   */
  hideTooltip() {
    const content = this.contentTarget
    const trigger = this.triggerTarget
    
    // Hide content
    content.hidden = true
    content.style.opacity = '0'
    
    // Remove aria-describedby
    trigger.removeAttribute('aria-describedby')
    
    // Stop auto-updating
    this.stopAutoUpdate()
    
    // Remove ESC listener
    window.removeEventListener('keydown', this.handleEscape)
    
    this.dispatchStateChange("ui:tooltip:hidden")
  }

  /**
   * Update tooltip position using Floating UI
   */
  async updatePosition() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    const { x, y } = await computePosition(
      this.triggerTarget,
      this.contentTarget,
      {
        placement: this.placementValue,
        middleware: [
          offset(this.offsetValue),
          flip(),
          shift({ padding: 5 })
        ]
      }
    )

    Object.assign(this.contentTarget.style, {
      left: `${x}px`,
      top: `${y}px`
    })
  }

  /**
   * Start auto-updating position on scroll/resize
   */
  startAutoUpdate() {
    // Simple auto-update using event listeners
    this.updatePositionBound = this.updatePosition.bind(this)
    window.addEventListener('scroll', this.updatePositionBound, true)
    window.addEventListener('resize', this.updatePositionBound)
  }

  /**
   * Stop auto-updating position
   */
  stopAutoUpdate() {
    if (this.updatePositionBound) {
      window.removeEventListener('scroll', this.updatePositionBound, true)
      window.removeEventListener('resize', this.updatePositionBound)
      this.updatePositionBound = null
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
   * Generate unique tooltip ID
   * @returns {string} Unique ID
   */
  generateTooltipId() {
    return `tooltip-${Math.random().toString(36).substr(2, 9)}`
  }
}
