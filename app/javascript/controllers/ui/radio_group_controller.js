import BaseController from "controllers/ui/base_controller"

/**
 * Radio Group Stimulus Controller
 * 
 * Manages radio button group with keyboard navigation and form integration
 * Supports arrow key navigation
 * 
 * Usage:
 *   <div data-controller="ui--radio-group" data-ui--radio-group-value-value="option1">
 *     <div>
 *       <input type="radio" id="opt1" name="options" value="option1" data-ui--radio-group-target="input" />
 *       <label for="opt1">Option 1</label>
 *     </div>
 *     <div>
 *       <input type="radio" id="opt2" name="options" value="option2" data-ui--radio-group-target="input" />
 *       <label for="opt2">Option 2</label>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - value (String): Selected radio value
 *   - orientation (String): "horizontal" or "vertical" (default: "vertical")
 * 
 * Actions:
 *   - select: Select a radio option
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:radio-group:changed - { value: string }
 */
export default class extends BaseController {
  static values = {
    value: String,
    orientation: { type: String, default: "vertical" }
  }

  static targets = ["input"]

  connect() {
    console.log('⚪ Radio Group controller connected', this.element)
    
    // Setup ARIA attributes
    this.element.setAttribute('role', 'radiogroup')
    
    // Setup input elements
    this.inputTargets.forEach((input, index) => {
      input.setAttribute('role', 'radio')
      input.setAttribute('aria-checked', input.checked ? 'true' : 'false')
      
      // Add event listener
      input.addEventListener('change', (e) => this.select(e))
      input.addEventListener('keydown', (e) => this.keydown(e))
      input.setAttribute('tabindex', input.checked ? '0' : '-1')
    })

    // Set initial value
    this.syncValue()
  }

  /**
   * Select a radio option
   * @param {Event} event - Change event
   */
  select(event) {
    const input = event.target
    if (!this.inputTargets.includes(input)) return

    console.log('⚪ Radio Group selected:', input.value)
    this.valueValue = input.value
    this.updateChecked()
    
    this.dispatchStateChange('ui:radio-group:changed', {
      value: this.valueValue
    })
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    const isVertical = this.orientationValue === 'vertical'
    const isHorizontal = this.orientationValue === 'horizontal'
    
    let shouldNavigate = false
    let direction = 0

    if (isVertical) {
      if (event.key === 'ArrowDown') {
        event.preventDefault()
        direction = 1
        shouldNavigate = true
      } else if (event.key === 'ArrowUp') {
        event.preventDefault()
        direction = -1
        shouldNavigate = true
      }
    } else if (isHorizontal) {
      if (event.key === 'ArrowRight') {
        event.preventDefault()
        direction = 1
        shouldNavigate = true
      } else if (event.key === 'ArrowLeft') {
        event.preventDefault()
        direction = -1
        shouldNavigate = true
      }
    }

    if (shouldNavigate) {
      const currentIndex = this.inputTargets.findIndex(
        input => input.getAttribute('aria-checked') === 'true'
      )
      const nextIndex = (currentIndex + direction + this.inputTargets.length) % this.inputTargets.length
      
      this.focusOption(nextIndex)
    }
  }

  /**
   * Focus and select an option by index
   * @param {number} index - Option index
   */
  focusOption(index) {
    const input = this.inputTargets[index]
    if (input) {
      input.focus()
      input.checked = true
      this.select({ target: input })
    }
  }

  /**
   * Update when value changes
   */
  valueValueChanged() {
    this.updateChecked()
  }

  /**
   * Update checked state and tabindex
   */
  updateChecked() {
    this.inputTargets.forEach(input => {
      const isChecked = input.value === this.valueValue
      input.checked = isChecked
      input.setAttribute('aria-checked', isChecked ? 'true' : 'false')
      input.setAttribute('tabindex', isChecked ? '0' : '-1')
    })
  }

  /**
   * Sync value from checked input
   */
  syncValue() {
    const checked = this.inputTargets.find(input => input.checked)
    if (checked && !this.hasValueValue) {
      this.valueValue = checked.value
    }
  }
}
