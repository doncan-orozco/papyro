import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset } from "@floating-ui/dom"

/**
 * Popover Stimulus Controller
 * 
 * Manages popover with click/focus toggle, smart positioning, and ESC key support
 * Similar to dropdown but typically used for non-menu content
 * Uses Floating UI for dynamic positioning
 * 
 * Usage:
 *   <div data-controller="ui--popover" data-ui--popover-placement-value="top">
 *     <button data-ui--popover-target="trigger" 
 *             data-action="click->ui--popover#toggle">
 *       Show Popover
 *     </button>
 *     <div data-ui--popover-target="content" role="dialog" hidden>
 *       Popover content...
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether popover is open
 *   - placement (String): Preferred position (default: "top")
 *   - offset (Number): Distance from trigger in pixels (default: 8)
 * 
 * Actions:
 *   - toggle: Toggle popover open/closed
 *   - close: Close popover
 * 
 * Events dispatched:
 *   - ui:popover:opened
 *   - ui:popover:closed
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false },
    placement: { type: String, default: "top" },
    offset: { type: Number, default: 8 }
  }

  static targets = ["trigger", "content"]

  connect() {
    console.log('💬 Popover controller connected', this.element)
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    this.escapeHandler = this.handleEscape.bind(this)
    this.cleanupAutoUpdate = null
    this.hasOpened = false
    this.hasInitialized = false
    
    // Setup content
    if (this.hasContentTarget) {
      this.contentTarget.hidden = true
      this.contentTarget.style.position = 'absolute'
      this.contentTarget.style.zIndex = '1000'
    }
  }

  disconnect() {
    this.removeEventListeners()
    this.stopAutoUpdate()
  }

  /**
   * Toggle popover open/closed
   * @param {Event} event - Click event
   */
  toggle(event) {
    console.log('💬 Popover toggle clicked', { open: this.openValue })
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  /**
   * Close popover
   * @param {Event} event - Event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  /**
   * Update when open value changes
   */
  async openValueChanged() {
    if (!this.hasInitialized) {
      this.hasInitialized = true
      if (!this.openValue) return
    }

    if (this.openValue) {
      await this.openPopover()
    } else {
      this.closePopover()
    }
  }

  /**
   * Open the popover
   */
  async openPopover() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    this.hasOpened = true

    // Show content
    this.contentTarget.hidden = false
    this.contentTarget.style.opacity = '0'
    
    // Position popover
    await this.updatePosition()
    
    // Fade in
    requestAnimationFrame(() => {
      this.contentTarget.style.opacity = '1'
    })
    
    // Start auto-updating position
    this.startAutoUpdate()
    
    // Add event listeners
    this.addEventListeners()
    
    // Focus first focusable element in popover
    const focusable = this.findFocusable(this.contentTarget)
    if (focusable.length > 0) {
      focusable[0].focus()
    } else {
      this.contentTarget.focus()
    }
    
    this.dispatchStateChange("ui:popover:opened")
  }

  /**
   * Close the popover
   */
  closePopover() {
    if (!this.hasContentTarget) return

    // Hide content
    this.contentTarget.style.opacity = '0'
    
    setTimeout(() => {
      if (this.hasContentTarget) {
        this.contentTarget.hidden = true
      }
    }, 150)
    
    // Stop auto-updating position
    this.stopAutoUpdate()
    
    // Remove event listeners
    this.removeEventListeners()
    
    // Restore focus to trigger only after an actual open
    if (this.hasTriggerTarget && this.hasOpened) {
      this.triggerTarget.focus()
    }
    
    this.dispatchStateChange("ui:popover:closed")
  }

  /**
   * Update popover position using Floating UI
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
   * Handle click outside
   * @param {MouseEvent} event - Click event
   */
  handleClickOutside(event) {
    if (!this.openValue) return
    
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  /**
   * Handle ESC key
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleEscape(event) {
    if (event.key === 'Escape' && this.openValue) {
      this.close()
    }
  }

  /**
   * Add event listeners
   */
  addEventListeners() {
    document.addEventListener('click', this.clickOutsideHandler)
    document.addEventListener('keydown', this.escapeHandler)
  }

  /**
   * Remove event listeners
   */
  removeEventListeners() {
    document.removeEventListener('click', this.clickOutsideHandler)
    document.removeEventListener('keydown', this.escapeHandler)
  }
}
