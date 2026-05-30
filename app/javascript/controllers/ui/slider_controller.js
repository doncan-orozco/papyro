import BaseController from "controllers/ui/base_controller"

/**
 * Slider Stimulus Controller
 * 
 * Manages numeric range slider with dragging and keyboard control
 * Supports single value or range selection
 * 
 * Usage:
 *   <div data-controller="ui--slider" data-ui--slider-value-value="50" data-ui--slider-min-value="0" data-ui--slider-max-value="100">
 *     <div data-ui--slider-target="track">
 *       <div data-ui--slider-target="thumb" data-action="pointerdown->ui--slider#startDrag">
 *         <input type="range" value="50" min="0" max="100" data-ui--slider-target="input" />
 *       </div>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - value (Number): Current slider value (default: 50)
 *   - min (Number): Minimum value (default: 0)
 *   - max (Number): Maximum value (default: 100)
 *   - step (Number): Step increment (default: 1)
 * 
 * Actions:
 *   - startDrag: Begin dragging
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:slider:changed - { value: number }
 */
export default class extends BaseController {
  static values = {
    value: { type: Number, default: 50 },
    min: { type: Number, default: 0 },
    max: { type: Number, default: 100 },
    step: { type: Number, default: 1 }
  }

  static targets = ["track", "thumb", "input"]

  connect() {
    this.isDragging = false
    this.dragStartX = 0
    this.dragStartValue = 0
    
    this.pointerMoveHandler = this.handlePointerMove.bind(this)
    this.pointerUpHandler = this.handlePointerUp.bind(this)
    
    // Sync input with slider value
    this.updateSlider()
  }

  disconnect() {
    this.stopDragging()
  }

  /**
   * Start dragging the slider
   * @param {PointerEvent} event - Pointer event
   */
  startDrag(event) {
    event.preventDefault()
    
    this.isDragging = true
    this.dragStartX = event.clientX
    this.dragStartValue = this.valueValue
    
    // Add event listeners
    document.addEventListener('pointermove', this.pointerMoveHandler)
    document.addEventListener('pointerup', this.pointerUpHandler)
    document.addEventListener('pointercancel', this.pointerUpHandler)
  }

  /**
   * Handle pointer move while dragging
   * @param {PointerEvent} event - Pointer event
   */
  handlePointerMove(event) {
    if (!this.isDragging || !this.hasTrackTarget) return

    const trackRect = this.trackTarget.getBoundingClientRect()
    const deltaX = event.clientX - this.dragStartX
    const trackWidth = trackRect.width
    
    // Calculate new value based on drag distance
    const range = this.maxValue - this.minValue
    const percentDelta = (deltaX / trackWidth) * range
    let newValue = this.dragStartValue + percentDelta
    
    // Clamp to min/max and apply step
    newValue = Math.max(this.minValue, Math.min(this.maxValue, newValue))
    newValue = Math.round(newValue / this.stepValue) * this.stepValue
    
    this.valueValue = newValue
  }

  /**
   * Handle pointer up (end drag)
   * @param {PointerEvent} event - Pointer event
   */
  handlePointerUp(event) {
    if (!this.isDragging) return

    this.stopDragging()
  }

  /**
   * Stop dragging
   */
  stopDragging() {
    this.isDragging = false
    
    document.removeEventListener('pointermove', this.pointerMoveHandler)
    document.removeEventListener('pointerup', this.pointerUpHandler)
    document.removeEventListener('pointercancel', this.pointerUpHandler)
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    let shouldUpdate = false

    switch (event.key) {
      case 'ArrowRight':
      case 'ArrowUp':
        event.preventDefault()
        this.valueValue = Math.min(this.valueValue + this.stepValue, this.maxValue)
        shouldUpdate = true
        break
      case 'ArrowLeft':
      case 'ArrowDown':
        event.preventDefault()
        this.valueValue = Math.max(this.valueValue - this.stepValue, this.minValue)
        shouldUpdate = true
        break
      case 'Home':
        event.preventDefault()
        this.valueValue = this.minValue
        shouldUpdate = true
        break
      case 'End':
        event.preventDefault()
        this.valueValue = this.maxValue
        shouldUpdate = true
        break
    }

    if (shouldUpdate) {
      this.updateSlider()
    }
  }

  /**
   * Update when value changes
   */
  valueValueChanged() {
    this.updateSlider()
  }

  /**
   * Update slider visuals and sync input
   */
  updateSlider() {
    // Sync input value
    if (this.hasInputTarget) {
      this.inputTarget.value = this.valueValue
    }

    // Update thumb position
    if (this.hasThumbTarget && this.hasTrackTarget) {
      const range = this.maxValue - this.minValue
      const percent = ((this.valueValue - this.minValue) / range) * 100
      this.thumbTarget.style.left = `${percent}%`
      this.thumbTarget.setAttribute('aria-valuenow', this.valueValue)
    }

    // Dispatch change event
    this.dispatchStateChange('ui:slider:changed', {
      value: this.valueValue
    })
  }
}
