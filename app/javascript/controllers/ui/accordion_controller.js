import BaseController from "controllers/ui/base_controller"

/**
 * Accordion Stimulus Controller
 * 
 * Manages expandable/collapsible accordion panels
 * Supports single or multiple open items
 * Full keyboard navigation (Arrow keys, Home, End)
 * 
 * Usage:
 *   <div data-controller="ui--accordion" data-ui--accordion-allow-multiple-value="false">
 *     <div data-ui--accordion-target="item">
 *       <button data-ui--accordion-target="trigger" data-action="click->ui--accordion#toggle">
 *         Trigger
 *       </button>
 *       <div data-ui--accordion-target="content">
 *         Content
 *       </div>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - allowMultiple (Boolean): Allow multiple items open simultaneously
 *   - defaultOpen (String): Comma-separated indices of initially open items
 * 
 * Actions:
 *   - toggle: Toggle item open/closed
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:accordion:opened - { index: number }
 *   - ui:accordion:closed - { index: number }
 */
export default class extends BaseController {
  static values = {
    allowMultiple: { type: Boolean, default: false },
    defaultOpen: String
  }

  static targets = ["item", "trigger", "content"]

  connect() {
    // Initialize default open items
    if (this.hasDefaultOpenValue) {
      const indices = this.defaultOpenValue.split(',').map(i => parseInt(i.trim(), 10))
      indices.forEach(index => {
        if (!isNaN(index) && index >= 0 && index < this.itemTargets.length) {
          this.openItem(index, false) // Don't dispatch events on init
        }
      })
    } else {
      // Ensure all items are closed by default
      this.itemTargets.forEach((_, index) => {
        this.closeItem(index, false)
      })
    }
  }

  /**
   * Toggle an accordion item
   * @param {Event} event - Click event
   */
  toggle(event) {
    const trigger = event.currentTarget
    const index = this.triggerTargets.indexOf(trigger)
    
    if (index === -1) return

    const isOpen = this.isItemOpen(index)
    
    if (isOpen) {
      this.closeItem(index)
    } else {
      // Close other items if single mode
      if (!this.allowMultipleValue) {
        this.closeAllItems()
      }
      this.openItem(index)
    }
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    const trigger = event.target
    if (!this.triggerTargets.includes(trigger)) return

    const currentIndex = this.triggerTargets.indexOf(trigger)
    let targetIndex = currentIndex

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        targetIndex = this.getCircularIndex(currentIndex, this.triggerTargets.length, 1)
        break
      case 'ArrowUp':
        event.preventDefault()
        targetIndex = this.getCircularIndex(currentIndex, this.triggerTargets.length, -1)
        break
      case 'Home':
        event.preventDefault()
        targetIndex = 0
        break
      case 'End':
        event.preventDefault()
        targetIndex = this.triggerTargets.length - 1
        break
      default:
        return
    }

    if (targetIndex !== currentIndex) {
      this.triggerTargets[targetIndex].focus()
    }
  }

  /**
   * Open an accordion item
   * @param {number} index - Item index
   * @param {boolean} dispatchEvent - Whether to dispatch event
   */
  openItem(index, dispatchEvent = true) {
    const trigger = this.triggerTargets[index]
    const content = this.contentTargets[index]
    
    if (!trigger || !content) return

    // Update trigger state
    trigger.setAttribute("data-state", "open")
    trigger.setAttribute("aria-expanded", "true")
    
    // Update content state
    content.setAttribute("data-state", "open")
    content.style.maxHeight = `${content.scrollHeight}px`
    
    if (dispatchEvent) {
      this.dispatchStateChange("ui:accordion:opened", { index })
    }
  }

  /**
   * Close an accordion item
   * @param {number} index - Item index
   * @param {boolean} dispatchEvent - Whether to dispatch event
   */
  closeItem(index, dispatchEvent = true) {
    const trigger = this.triggerTargets[index]
    const content = this.contentTargets[index]
    
    if (!trigger || !content) return

    // Update trigger state
    trigger.setAttribute("data-state", "closed")
    trigger.setAttribute("aria-expanded", "false")
    
    // Update content state
    content.setAttribute("data-state", "closed")
    content.style.maxHeight = "0"
    
    if (dispatchEvent) {
      this.dispatchStateChange("ui:accordion:closed", { index })
    }
  }

  /**
   * Close all accordion items
   */
  closeAllItems() {
    this.itemTargets.forEach((_, index) => {
      this.closeItem(index)
    })
  }

  /**
   * Check if an item is open
   * @param {number} index - Item index
   * @returns {boolean} True if item is open
   */
  isItemOpen(index) {
    const trigger = this.triggerTargets[index]
    return trigger?.getAttribute("data-state") === "open"
  }
}
