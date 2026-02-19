import BaseController from "controllers/ui/base_controller"

/**
 * Switch Stimulus Controller
 * 
 * Handles toggle interactions for switch components
 * Updates data-state and aria-checked attributes
 * Supports form integration with hidden input
 * 
 * Usage:
 *   <button data-controller="ui--switch" data-ui--switch-checked-value="false">
 *     <span data-ui--switch-target="thumb"></span>
 *   </button>
 * 
 * Values:
 *   - checked (Boolean): Current checked state
 *   - disabled (Boolean): Whether switch is disabled
 *   - name (String): Form field name (creates hidden input)
 *   - value (String): Form field value when checked
 * 
 * Actions:
 *   - toggle: Toggle checked state (click or Space/Enter)
 * 
 * Events dispatched:
 *   - ui:switch:changed - { checked: boolean }
 */
export default class extends BaseController {
  static values = {
    checked: { type: Boolean, default: false },
    disabled: { type: Boolean, default: false },
    name: String,
    value: { type: String, default: "1" }
  }

  static targets = ["thumb", "input"]

  connect() {
    console.log('🔘 Switch controller connected', this.element)
    // Set initial state
    this.updateState()
    
    // Create hidden input for form if name is provided
    if (this.hasNameValue && !this.hasInputTarget) {
      this.createHiddenInput()
    }
  }

  /**
   * Toggle the switch state
   * @param {Event} event - Click or keyboard event
   */
  toggle(event) {
    console.log('🔘 Switch toggle clicked', { checked: this.checkedValue })
    if (this.disabledValue) {
      event?.preventDefault()
      return
    }

    this.checkedValue = !this.checkedValue
  }

  /**
   * Handle keyboard events (Space and Enter should toggle)
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    if (this.disabledValue) return
    
    if (event.key === ' ' || event.key === 'Enter') {
      event.preventDefault()
      this.toggle(event)
    }
  }

  /**
   * Update when checked value changes
   */
  checkedValueChanged() {
    this.updateState()
    this.updateHiddenInput()
    this.dispatchChangeEvent()
  }

  /**
   * Update when disabled value changes
   */
  disabledValueChanged() {
    this.element.disabled = this.disabledValue
    this.element.setAttribute('aria-disabled', this.disabledValue.toString())
  }

  /**
   * Update visual and ARIA state
   */
  updateState() {
    const state = this.checkedValue ? "checked" : "unchecked"
    
    // Update data-state on button
    this.element.setAttribute("data-state", state)
    
    // Update aria-checked
    this.element.setAttribute("aria-checked", this.checkedValue.toString())
    
    // Update thumb if present
    if (this.hasThumbTarget) {
      this.thumbTarget.setAttribute("data-state", state)
    }
  }

  /**
   * Create hidden input for form submission
   */
  createHiddenInput() {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.nameValue
    input.value = this.checkedValue ? this.valueValue : "0"
    input.dataset.uiSwitchTarget = "input"
    
    this.element.parentElement.appendChild(input)
  }

  /**
   * Update hidden input value
   */
  updateHiddenInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = this.checkedValue ? this.valueValue : "0"
    }
  }

  /**
   * Dispatch custom change event
   */
  dispatchChangeEvent() {
    this.dispatchStateChange("ui:switch:changed", {
      checked: this.checkedValue,
      name: this.nameValue,
      value: this.checkedValue ? this.valueValue : "0"
    })
  }
}
