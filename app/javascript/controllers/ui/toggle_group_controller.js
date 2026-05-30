import BaseController from "controllers/ui/base_controller"

/**
 * Toggle Group Stimulus Controller
 * 
 * Manages group of toggle buttons with single or multi-select support
 * Supports keyboard navigation with arrow keys
 * 
 * Usage:
 *   <div data-controller="ui--toggle-group" 
 *        data-ui--toggle-group-type-value="single"
 *        data-ui--toggle-group-value-value="option1">
 *     <button data-ui--toggle-group-target="toggle" 
 *             data-action="click->ui--toggle-group#selectToggle"
 *             data-value="option1">
 *       Option 1
 *     </button>
 *     <button data-ui--toggle-group-target="toggle" 
 *             data-action="click->ui--toggle-group#selectToggle"
 *             data-value="option2">
 *       Option 2
 *     </button>
 *   </div>
 * 
 * Values:
 *   - value (String): Selected value(s), comma-separated for multi-select
 *   - type (String): "single" or "multiple" (default: "single")
 * 
 * Actions:
 *   - selectToggle: Select a toggle option
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:toggle-group:changed - { value: string, values: string[] }
 */
export default class extends BaseController {
  static values = {
    value: String,
    type: { type: String, default: "single" }
  }

  static targets = ["toggle"]

  connect() {
    
    // Setup ARIA attributes
    this.element.setAttribute('role', 'group')
    
    // Setup toggle elements
    this.toggleTargets.forEach((toggle, index) => {
      toggle.setAttribute('role', 'button')
      toggle.setAttribute('aria-pressed', 'false')
      toggle.addEventListener('keydown', (e) => this.keydown(e))
    })

    // Set initial selected state
    this.updateToggles()
  }

  /**
   * Select a toggle option
   * @param {Event} event - Click event
   */
  selectToggle(event) {
    event?.preventDefault()
    
    const toggle = event.currentTarget
    if (!this.toggleTargets.includes(toggle)) return

    const toggleValue = toggle.getAttribute('data-value')
    if (!toggleValue) return


    if (this.typeValue === 'single') {
      // Single select - replace value
      this.valueValue = toggleValue
    } else {
      // Multiple select - toggle in array
      const values = this.getSelectedValues()
      const index = values.indexOf(toggleValue)
      
      if (index > -1) {
        values.splice(index, 1)
      } else {
        values.push(toggleValue)
      }
      
      this.valueValue = values.join(',')
    }

    this.updateToggles()
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    const toggle = event.target
    if (!this.toggleTargets.includes(toggle)) return

    let shouldNavigate = false
    let direction = 0

    switch (event.key) {
      case 'ArrowRight':
      case 'ArrowDown':
        event.preventDefault()
        direction = 1
        shouldNavigate = true
        break
      case 'ArrowLeft':
      case 'ArrowUp':
        event.preventDefault()
        direction = -1
        shouldNavigate = true
        break
      case ' ':
      case 'Enter':
        event.preventDefault()
        this.selectToggle({ currentTarget: toggle })
        return
    }

    if (shouldNavigate) {
      const currentIndex = this.toggleTargets.indexOf(toggle)
      const nextIndex = (currentIndex + direction + this.toggleTargets.length) % this.toggleTargets.length
      this.toggleTargets[nextIndex].focus()
    }
  }

  /**
   * Update when value changes
   */
  valueValueChanged() {
    this.updateToggles()
  }

  /**
   * Update toggle pressed states
   */
  updateToggles() {
    const selectedValues = this.getSelectedValues()

    this.toggleTargets.forEach(toggle => {
      const toggleValue = toggle.getAttribute('data-value')
      const isSelected = selectedValues.includes(toggleValue)

      toggle.setAttribute('data-state', isSelected ? 'on' : 'off')
      toggle.setAttribute('aria-pressed', isSelected ? 'true' : 'false')
    })

    // Dispatch change event
    this.dispatchStateChange('ui:toggle-group:changed', {
      value: this.valueValue,
      values: selectedValues
    })
  }

  /**
   * Get array of selected values
   * @returns {string[]} Selected values
   */
  getSelectedValues() {
    if (!this.hasValueValue) return []
    
    if (this.typeValue === 'single') {
      return [this.valueValue]
    } else {
      return this.valueValue.split(',').filter(v => v.length > 0)
    }
  }
}
