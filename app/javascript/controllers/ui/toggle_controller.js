import BaseController from "controllers/ui/base_controller"

/**
 * Toggle Stimulus Controller
 * 
 * Manages toggle button with pressed state
 * Similar to Switch but for button-style toggles
 * Supports keyboard activation (Space/Enter)
 * 
 * Usage:
 *   <button data-controller="ui--toggle" 
 *           data-ui--toggle-pressed-value="false"
 *           data-action="click->ui--toggle#toggle keydown->ui--toggle#keydown">
 *     Bold
 *   </button>
 * 
 * Values:
 *   - pressed (Boolean): Whether toggle is in pressed state (default: false)
 *   - disabled (Boolean): Whether toggle is disabled (default: false)
 * 
 * Actions:
 *   - toggle: Toggle pressed state
 *   - keydown: Handle keyboard activation
 * 
 * Events dispatched:
 *   - ui:toggle:pressed - { pressed: boolean }
 */
export default class extends BaseController {
  static values = {
    pressed: { type: Boolean, default: false },
    disabled: { type: Boolean, default: false }
  }

  connect() {
    
    // Ensure element is a button or has button role
    if (this.element.tagName !== 'BUTTON' && !this.element.hasAttribute('role')) {
      this.element.setAttribute('role', 'button')
    }
    
    // Make focusable if not already
    if (!this.element.hasAttribute('tabindex')) {
      this.element.setAttribute('tabindex', '0')
    }
    
    // Update state
    this.updateState()
  }

  /**
   * Toggle pressed state
   * @param {Event} event - Click event
   */
  toggle(event) {
    if (this.disabledValue) {
      event?.preventDefault()
      return
    }

    event?.preventDefault()
    this.pressedValue = !this.pressedValue
  }

  /**
   * Handle keyboard activation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    if (this.disabledValue) return
    
    // Space or Enter to toggle
    if (event.key === ' ' || event.key === 'Enter') {
      event.preventDefault()
      this.toggle()
    }
  }

  /**
   * Update when pressed value changes
   */
  pressedValueChanged() {
    this.updateState()
  }

  /**
   * Update toggle state
   */
  updateState() {
    // Update aria-pressed
    this.element.setAttribute('aria-pressed', this.pressedValue ? 'true' : 'false')
    
    // Update data-state
    this.element.setAttribute('data-state', this.pressedValue ? 'on' : 'off')
    
    // Update disabled attribute
    if (this.disabledValue) {
      this.element.setAttribute('disabled', '')
      this.element.setAttribute('aria-disabled', 'true')
    } else {
      this.element.removeAttribute('disabled')
      this.element.setAttribute('aria-disabled', 'false')
    }

    // Dispatch change event
    this.dispatchStateChange('ui:toggle:pressed', {
      pressed: this.pressedValue
    })
  }

  /**
   * Handle disabled value change
   */
  disabledValueChanged() {
    this.updateState()
  }
}
