import BaseController from "controllers/ui/base_controller"

/**
 * Resizable Stimulus Controller
 * 
 * Manages resizable panels with drag-to-resize functionality
 * Supports edge dragging and optional dimension persistence
 * 
 * Usage:
 *   <div data-controller="ui--resizable" style="width: 400px; height: 300px;">
 *     <div data-ui--resizable-target="panel" style="width: 100%; height: 100%;">
 *       Content here
 *     </div>
 *     <div data-ui--resizable-target="handle" 
 *          data-handle-position="right"
 *          data-action="pointerdown->ui--resizable#startResize"
 *          style="position: absolute; right: 0; top: 0; width: 4px; height: 100%; cursor: col-resize;">
 *     </div>
 *   </div>
 * 
 * Values:
 *   - minWidth (Number): Minimum width in pixels (default: 200)
 *   - minHeight (Number): Minimum height in pixels (default: 200)
 *   - maxWidth (Number): Maximum width in pixels (default: 0 = unlimited)
 *   - maxHeight (Number): Maximum height in pixels (default: 0 = unlimited)
 * 
 * Actions:
 *   - startResize: Begin resizing from handle
 * 
 * Events dispatched:
 *   - ui:resizable:resized - { width: number, height: number }
 */
export default class extends BaseController {
  static values = {
    minWidth: { type: Number, default: 200 },
    minHeight: { type: Number, default: 200 },
    maxWidth: { type: Number, default: 0 },
    maxHeight: { type: Number, default: 0 }
  }

  static targets = ["panel", "handle"]

  connect() {
    this.isResizing = false
    this.resizeStartX = 0
    this.resizeStartY = 0
    this.resizeStartWidth = 0
    this.resizeStartHeight = 0
    this.handlePosition = null
    
    this.pointerMoveHandler = this.handlePointerMove.bind(this)
    this.pointerUpHandler = this.handlePointerUp.bind(this)
  }

  disconnect() {
    this.stopResizing()
  }

  /**
   * Start resizing from handle
   * @param {PointerEvent} event - Pointer event
   */
  startResize(event) {
    event.preventDefault()

    const handle = event.currentTarget
    this.handlePosition = handle.getAttribute('data-handle-position') || 'right'
    
    this.isResizing = true
    this.resizeStartX = event.clientX
    this.resizeStartY = event.clientY
    this.resizeStartWidth = this.element.offsetWidth
    this.resizeStartHeight = this.element.offsetHeight

    // Set cursor
    handle.style.cursor = this.handlePosition === 'right' || this.handlePosition === 'left' 
      ? 'col-resize' 
      : 'row-resize'

    // Add event listeners
    document.addEventListener('pointermove', this.pointerMoveHandler)
    document.addEventListener('pointerup', this.pointerUpHandler)
    document.addEventListener('pointercancel', this.pointerUpHandler)

    // Set dragging flag
    this.element.setAttribute('data-resizing', 'true')
  }

  /**
   * Handle pointer move while resizing
   * @param {PointerEvent} event - Pointer event
   */
  handlePointerMove(event) {
    if (!this.isResizing) return

    let newWidth = this.resizeStartWidth
    let newHeight = this.resizeStartHeight

    // Calculate deltas
    const deltaX = event.clientX - this.resizeStartX
    const deltaY = event.clientY - this.resizeStartY

    // Update dimensions based on handle position
    if (this.handlePosition === 'right') {
      newWidth = this.resizeStartWidth + deltaX
    } else if (this.handlePosition === 'left') {
      newWidth = this.resizeStartWidth - deltaX
    } else if (this.handlePosition === 'bottom') {
      newHeight = this.resizeStartHeight + deltaY
    } else if (this.handlePosition === 'top') {
      newHeight = this.resizeStartHeight - deltaY
    }

    // Apply constraints
    newWidth = Math.max(this.minWidthValue, newWidth)
    newHeight = Math.max(this.minHeightValue, newHeight)

    if (this.maxWidthValue > 0) {
      newWidth = Math.min(this.maxWidthValue, newWidth)
    }

    if (this.maxHeightValue > 0) {
      newHeight = Math.min(this.maxHeightValue, newHeight)
    }

    // Apply dimensions
    this.element.style.width = `${newWidth}px`
    this.element.style.height = `${newHeight}px`

    // Dispatch resize event
    this.dispatchStateChange('ui:resizable:resized', {
      width: newWidth,
      height: newHeight
    })
  }

  /**
   * Handle pointer up (end resize)
   * @param {PointerEvent} event - Pointer event
   */
  handlePointerUp(event) {
    if (!this.isResizing) return
    this.stopResizing()
  }

  /**
   * Stop resizing
   */
  stopResizing() {
    this.isResizing = false
    
    document.removeEventListener('pointermove', this.pointerMoveHandler)
    document.removeEventListener('pointerup', this.pointerUpHandler)
    document.removeEventListener('pointercancel', this.pointerUpHandler)

    // Remove dragging flag
    this.element.removeAttribute('data-resizing')
  }
}
