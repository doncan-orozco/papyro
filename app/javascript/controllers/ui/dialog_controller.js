import BaseController from "controllers/ui/base_controller"

/**
 * Dialog (Modal) Stimulus Controller
 * 
 * Manages modal dialogs with focus trap and scroll lock
 * Follows WAI-ARIA Dialog pattern
 * 
 * Usage:
 *   <div data-controller="ui--dialog" data-ui--dialog-open-value="false">
 *     <button data-action="click->ui--dialog#open">Open Dialog</button>
 *     
 *     <div data-ui--dialog-target="overlay" hidden></div>
 *     <div data-ui--dialog-target="content" role="dialog" aria-modal="true" hidden>
 *       <button data-action="click->ui--dialog#close" data-ui--dialog-target="closeButton">
 *         Close
 *       </button>
 *       Dialog content...
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether dialog is open
 *   - closeOnOverlayClick (Boolean): Close when clicking overlay (default: true)
 *   - closeOnEsc (Boolean): Close when pressing ESC (default: true)
 * 
 * Actions:
 *   - open: Open the dialog
 *   - close: Close the dialog
 *   - toggle: Toggle dialog open/closed
 * 
 * Events dispatched:
 *   - ui:dialog:opened
 *   - ui:dialog:closed
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false },
    closeOnOverlayClick: { type: Boolean, default: true },
    closeOnEsc: { type: Boolean, default: true }
  }

  static targets = ["overlay", "content", "closeButton"]

  connect() {
    console.log('🗨️ Dialog controller connected', this.element)
    this.previouslyFocusedElement = null
    this.keydownHandler = this.handleKeydown.bind(this)
    this.overlayClickHandler = this.handleOverlayClick.bind(this)
    this.hasOpened = false
    this.hasInitialized = false
  }

  disconnect() {
    this.removeEventListeners()
    this.restoreBodyScroll()
  }

  /**
   * Open the dialog
   * @param {Event} event - Event
   */
  open(event) {
    console.log('🗨️ Dialog open clicked')
    event?.preventDefault()
    this.openValue = true
  }

  /**
   * Close the dialog
   * @param {Event} event - Event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  /**
   * Toggle dialog open/closed
   * @param {Event} event - Event
   */
  toggle(event) {
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  /**
   * Update when open value changes
   */
  openValueChanged() {
    if (!this.hasInitialized) {
      this.hasInitialized = true
      if (!this.openValue) return
    }

    if (this.openValue) {
      this.openDialog()
    } else {
      this.closeDialog()
    }
  }

  /**
   * Open the dialog
   */
  openDialog() {
    this.hasOpened = true
    // Save currently focused element
    this.previouslyFocusedElement = document.activeElement

    // Show overlay and content
    if (this.hasOverlayTarget) {
      this.showElement(this.overlayTarget)
    }
    
    if (this.hasContentTarget) {
      this.showElement(this.contentTarget)
    }

    // Prevent body scroll
    this.preventBodyScroll()

    // Focus first focusable element or content itself
    this.focusFirstElement()

    // Add event listeners
    this.addEventListeners()

    this.dispatchStateChange("ui:dialog:opened")
  }

  /**
   * Close the dialog
   */
  closeDialog() {
    // Hide overlay and content
    if (this.hasOverlayTarget) {
      this.hideElement(this.overlayTarget)
    }
    
    if (this.hasContentTarget) {
      this.hideElement(this.contentTarget)
    }

    // Restore body scroll
    this.restoreBodyScroll()

    // Restore focus to previously focused element
    if (this.previouslyFocusedElement && this.hasOpened) {
      this.previouslyFocusedElement.focus()
      this.previouslyFocusedElement = null
    }

    // Remove event listeners
    this.removeEventListeners()

    this.dispatchStateChange("ui:dialog:closed")
  }

  /**
   * Show an element with fade-in effect
   * @param {HTMLElement} element - Element to show
   */
  showElement(element) {
    element.hidden = false
    if (element.style.display === 'none') {
      element.style.display = ''
    }
    element.style.opacity = '0'
    
    // Force reflow for transition
    element.offsetHeight
    
    element.style.opacity = '1'

    if (element.dataset.dialogTransition === 'slide') {
      element.style.transform = 'translateX(0)'
    }
  }

  /**
   * Hide an element with fade-out effect
   * @param {HTMLElement} element - Element to hide
   */
  hideElement(element) {
    element.style.opacity = '0'

    if (element.dataset.dialogTransition === 'slide') {
      element.style.transform = 'translateX(100%)'
    }
    
    // Hide after transition
    setTimeout(() => {
      element.hidden = true
    }, 200) // Match transition-all duration-200
  }

  /**
   * Focus first focusable element in dialog
   */
  focusFirstElement() {
    if (!this.hasContentTarget) return

    const firstFocusable = this.findFirstFocusable(this.contentTarget)
    
    if (firstFocusable) {
      // Small delay to ensure element is visible
      setTimeout(() => firstFocusable.focus(), 100)
    } else {
      // Focus dialog content itself if no focusable elements
      this.contentTarget.tabIndex = -1
      this.contentTarget.focus()
    }
  }

  /**
   * Handle keyboard events
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeydown(event) {
    // Handle ESC key
    if (event.key === 'Escape' && this.closeOnEscValue) {
      event.preventDefault()
      this.close()
      return
    }

    // Handle Tab key for focus trap
    if (event.key === 'Tab' && this.hasContentTarget) {
      this.trapFocus(event, this.contentTarget)
    }
  }

  /**
   * Handle overlay click
   * @param {MouseEvent} event - Click event
   */
  handleOverlayClick(event) {
    if (!this.closeOnOverlayClickValue) return
    
    // Only close if clicking directly on overlay (not content)
    if (this.hasOverlayTarget && event.target === this.overlayTarget) {
      this.close()
    }
  }

  /**
   * Add event listeners
   */
  addEventListeners() {
    document.addEventListener('keydown', this.keydownHandler)
    
    if (this.hasOverlayTarget) {
      this.overlayTarget.addEventListener('click', this.overlayClickHandler)
    }
  }

  /**
   * Remove event listeners
   */
  removeEventListeners() {
    document.removeEventListener('keydown', this.keydownHandler)
    
    if (this.hasOverlayTarget) {
      this.overlayTarget.removeEventListener('click', this.overlayClickHandler)
    }
  }
}
