import BaseController from "controllers/ui/base_controller"

/**
 * Collapsible Stimulus Controller
 * 
 * Manages a single expandable/collapsible region
 * Simpler than accordion - single item only
 * 
 * Usage:
 *   <div data-controller="ui--collapsible" data-ui--collapsible-open-value="false">
 *     <button data-ui--collapsible-target="trigger" 
 *             data-action="click->ui--collapsible#toggle">
 *       Toggle
 *     </button>
 *     <div data-ui--collapsible-target="content">
 *       Content
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether collapsible is open (default: false)
 * 
 * Actions:
 *   - toggle: Toggle open/closed
 *   - open: Open the collapsible
 *   - close: Close the collapsible
 * 
 * Events dispatched:
 *   - ui:collapsible:opened
 *   - ui:collapsible:closed
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false }
  }

  static targets = ["trigger", "content"]

  connect() {
    console.log('↔️ Collapsible controller connected', this.element)
    
    // Setup trigger ARIA
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', this.openValue)
      this.triggerTarget.setAttribute('aria-controls', this.contentTarget?.id || 'collapsible-content')
    }
    
    // Update initial state
    this.updateState()
  }

  /**
   * Toggle open/closed
   * @param {Event} event - Click event
   */
  toggle(event) {
    console.log('↔️ Collapsible toggle clicked')
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  /**
   * Open the collapsible
   * @param {Event} event - Event
   */
  open(event) {
    event?.preventDefault()
    this.openValue = true
  }

  /**
   * Close the collapsible
   * @param {Event} event - Event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  /**
   * Update when open value changes
   */
  openValueChanged() {
    this.updateState()
  }

  /**
   * Update the collapsible state
   */
  updateState() {
    if (!this.hasContentTarget) return

    if (this.openValue) {
      this.openContent()
    } else {
      this.closeContent()
    }
  }

  /**
   * Open the collapsible content
   */
  openContent() {
    if (!this.hasTriggerTarget || !this.hasContentTarget) return

    // Update trigger
    this.triggerTarget.setAttribute('data-state', 'open')
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    
    // Update content
    this.contentTarget.setAttribute('data-state', 'open')
    this.contentTarget.style.maxHeight = `${this.contentTarget.scrollHeight}px`
    this.contentTarget.style.opacity = '1'
    this.contentTarget.style.visibility = 'visible'
    
    this.dispatchStateChange('ui:collapsible:opened')
  }

  /**
   * Close the collapsible content
   */
  closeContent() {
    if (!this.hasTriggerTarget || !this.hasContentTarget) return

    // Update trigger
    this.triggerTarget.setAttribute('data-state', 'closed')
    this.triggerTarget.setAttribute('aria-expanded', 'false')
    
    // Update content
    this.contentTarget.setAttribute('data-state', 'closed')
    this.contentTarget.style.maxHeight = '0'
    this.contentTarget.style.opacity = '0'
    this.contentTarget.style.visibility = 'hidden'
    
    this.dispatchStateChange('ui:collapsible:closed')
  }
}
