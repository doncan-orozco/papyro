import { Controller } from "@hotwired/stimulus"

/**
 * Base controller for UI components with shared utilities
 * Provides common functionality for state management, focus handling, and events
 */
export default class extends Controller {
  /**
   * Toggle state attribute on an element
   * @param {HTMLElement} element - Element to update
   * @param {boolean} isOpen - New state
   * @param {string} attribute - Attribute name (default: "data-state")
   */
  toggleState(element, isOpen, attribute = "data-state") {
    if (!element) return
    
    const state = isOpen ? "open" : "closed"
    element.setAttribute(attribute, state)
  }

  /**
   * Set active state on an element
   * @param {HTMLElement} element - Element to update
   * @param {boolean} isActive - New state
   */
  setActiveState(element, isActive) {
    if (!element) return
    
    element.setAttribute("data-state", isActive ? "active" : "inactive")
  }

  /**
   * Find all focusable elements within a container
   * @param {HTMLElement} container - Container element
   * @returns {Array<HTMLElement>} Array of focusable elements
   */
  findFocusable(container) {
    if (!container) return []
    
    const selector = [
      'a[href]',
      'button:not([disabled])',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])',
    ].join(', ')
    
    return Array.from(container.querySelectorAll(selector))
  }

  /**
   * Find first focusable element
   * @param {HTMLElement} container - Container element
   * @returns {HTMLElement|null} First focusable element or null
   */
  findFirstFocusable(container) {
    const focusable = this.findFocusable(container)
    return focusable[0] || null
  }

  /**
   * Trap focus within container (for dialogs, dropdowns)
   * @param {KeyboardEvent} event - Keyboard event
   * @param {HTMLElement} container - Container to trap focus within
   */
  trapFocus(event, container) {
    if (event.key !== 'Tab') return
    
    const focusable = this.findFocusable(container)
    if (focusable.length === 0) return
    
    const firstFocusable = focusable[0]
    const lastFocusable = focusable[focusable.length - 1]
    
    if (event.shiftKey) {
      // Shift + Tab
      if (document.activeElement === firstFocusable) {
        event.preventDefault()
        lastFocusable.focus()
      }
    } else {
      // Tab
      if (document.activeElement === lastFocusable) {
        event.preventDefault()
        firstFocusable.focus()
      }
    }
  }

  /**
   * Dispatch custom event from this controller's element
   * @param {string} eventName - Event name (will be prefixed with controller name)
   * @param {Object} detail - Event detail object
   */
  dispatchStateChange(eventName, detail = {}) {
    const event = new CustomEvent(eventName, {
      bubbles: true,
      cancelable: true,
      detail
    })
    this.element.dispatchEvent(event)
  }

  /**
   * Click outside handler - commonly used for dropdowns, dialogs
   * @param {MouseEvent} event - Click event
   * @param {HTMLElement} container - Container element
   * @param {Function} callback - Callback to execute on outside click
   */
  handleClickOutside(event, container, callback) {
    if (!container.contains(event.target)) {
      callback(event)
    }
  }

  /**
   * Prevent body scroll (for dialogs/modals)
   */
  preventBodyScroll() {
    const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth
    document.body.style.overflow = 'hidden'
    if (scrollbarWidth > 0) {
      document.body.style.paddingRight = `${scrollbarWidth}px`
    }
  }

  /**
   * Restore body scroll
   */
  restoreBodyScroll() {
    document.body.style.overflow = ''
    document.body.style.paddingRight = ''
  }

  /**
   * Get next index in a circular list
   * @param {number} current - Current index
   * @param {number} total - Total items
   * @param {number} direction - Direction (1 for next, -1 for previous)
   * @returns {number} Next index
   */
  getCircularIndex(current, total, direction = 1) {
    const next = current + direction
    if (next >= total) return 0
    if (next < 0) return total - 1
    return next
  }

  /**
   * Debounce function calls
   * @param {Function} func - Function to debounce
   * @param {number} wait - Wait time in milliseconds
   * @returns {Function} Debounced function
   */
  debounce(func, wait = 200) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }
}
