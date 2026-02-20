import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset } from "@floating-ui/dom"

/**
 * Context Menu Stimulus Controller
 * 
 * Manages context menu triggered by right-click with keyboard navigation
 * Uses Floating UI for dynamic positioning
 * 
 * Usage:
 *   <div data-controller="ui--context-menu">
 *     <div data-ui--context-menu-target="trigger" 
 *          data-action="contextmenu->ui--context-menu#open">
 *       Right-click here
 *     </div>
 *     <div data-ui--context-menu-target="content" role="menu" hidden style="position: absolute">
 *       <button data-ui--context-menu-target="item" role="menuitem">Cut</button>
 *       <button data-ui--context-menu-target="item" role="menuitem">Copy</button>
 *       <button data-ui--context-menu-target="item" role="menuitem">Paste</button>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether context menu is open
 * 
 * Actions:
 *   - open: Open context menu at cursor position
 *   - close: Close context menu
 *   - navigate: Navigate with arrow keys
 *   - select: Select menu item
 * 
 * Events dispatched:
 *   - ui:context-menu:opened
 *   - ui:context-menu:closed
 *   - ui:context-menu:selected - { item: HTMLElement }
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false }
  }

  static targets = ["trigger", "content", "item"]

  connect() {
    console.log('📋 Context Menu controller connected', this.element)
    this.focusedItemIndex = -1
    this.contextMenuX = 0
    this.contextMenuY = 0
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    this.escapeHandler = this.handleEscape.bind(this)
    this.cleanupAutoUpdate = null
    
    // Setup content
    if (this.hasContentTarget) {
      this.contentTarget.hidden = true
      this.contentTarget.style.position = 'absolute'
      this.contentTarget.style.zIndex = '1001'
    }
  }

  disconnect() {
    this.removeEventListeners()
    this.stopAutoUpdate()
  }

  /**
   * Open context menu at cursor position
   * @param {MouseEvent} event - Right-click event
   */
  open(event) {
    console.log('📋 Context Menu open')
    event.preventDefault()
    
    this.contextMenuX = event.clientX
    this.contextMenuY = event.clientY
    this.openValue = true
  }

  /**
   * Close context menu
   * @param {Event} event - Event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  navigate(event) {
    if (!this.openValue) return

    const items = this.getNavigableItems()
    if (items.length === 0) return

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.focusNextItem(items)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.focusPreviousItem(items)
        break
      case 'Home':
        event.preventDefault()
        this.focusFirstItem(items)
        break
      case 'End':
        event.preventDefault()
        this.focusLastItem(items)
        break
      case 'Escape':
        event.preventDefault()
        this.close()
        break
    }
  }

  /**
   * Select a menu item
   * @param {Event} event - Click or keyboard event
   */
  select(event) {
    const item = event.currentTarget
    
    // Dispatch selection event
    this.dispatchStateChange("ui:context-menu:selected", { item })
    
    // Close menu after selection
    this.close()
  }

  /**
   * Update when open value changes
   */
  async openValueChanged() {
    if (this.openValue) {
      await this.openMenu()
    } else {
      this.closeMenu()
    }
  }

  /**
   * Open the context menu
   */
  async openMenu() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    // Show content
    this.contentTarget.hidden = false
    this.contentTarget.style.opacity = '0'
    
    // Position at cursor
    this.contentTarget.style.left = `${this.contextMenuX}px`
    this.contentTarget.style.top = `${this.contextMenuY}px`
    
    // Fade in
    requestAnimationFrame(() => {
      this.contentTarget.style.opacity = '1'
    })
    
    // Check if menu is off-screen and adjust
    await this.checkBounds()
    
    // Focus first item
    const items = this.getNavigableItems()
    if (items.length > 0) {
      this.focusItem(items[0])
      this.focusedItemIndex = 0
    }
    
    // Add event listeners
    this.addEventListeners()
    
    this.dispatchStateChange("ui:context-menu:opened")
  }

  /**
   * Close the context menu
   */
  closeMenu() {
    if (!this.hasContentTarget) return

    // Hide content
    this.contentTarget.style.opacity = '0'
    
    setTimeout(() => {
      if (this.hasContentTarget) {
        this.contentTarget.hidden = true
      }
    }, 150)
    
    // Remove event listeners
    this.removeEventListeners()
    
    this.dispatchStateChange("ui:context-menu:closed")
  }

  /**
   * Check if menu is off-screen and adjust position
   */
  async checkBounds() {
    if (!this.hasContentTarget) return

    const rect = this.contentTarget.getBoundingClientRect()
    const menuX = this.contextMenuX
    const menuY = this.contextMenuY
    
    // Adjust X if off right edge
    if (rect.right > window.innerWidth) {
      this.contentTarget.style.left = `${window.innerWidth - rect.width - 8}px`
    }
    
    // Adjust Y if off bottom edge
    if (rect.bottom > window.innerHeight) {
      this.contentTarget.style.top = `${window.innerHeight - rect.height - 8}px`
    }
  }

  /**
   * Get navigable menu items
   * @returns {HTMLElement[]} Menu items
   */
  getNavigableItems() {
    return this.itemTargets.filter(item => !item.disabled)
  }

  /**
   * Focus next item
   * @param {HTMLElement[]} items - Menu items
   */
  focusNextItem(items) {
    this.focusedItemIndex = Math.min(this.focusedItemIndex + 1, items.length - 1)
    this.focusItem(items[this.focusedItemIndex])
  }

  /**
   * Focus previous item
   * @param {HTMLElement[]} items - Menu items
   */
  focusPreviousItem(items) {
    this.focusedItemIndex = Math.max(this.focusedItemIndex - 1, 0)
    this.focusItem(items[this.focusedItemIndex])
  }

  /**
   * Focus first item
   * @param {HTMLElement[]} items - Menu items
   */
  focusFirstItem(items) {
    if (items.length > 0) {
      this.focusedItemIndex = 0
      this.focusItem(items[0])
    }
  }

  /**
   * Focus last item
   * @param {HTMLElement[]} items - Menu items
   */
  focusLastItem(items) {
    if (items.length > 0) {
      this.focusedItemIndex = items.length - 1
      this.focusItem(items[this.focusedItemIndex])
    }
  }

  /**
   * Focus a menu item
   * @param {HTMLElement} item - Item to focus
   */
  focusItem(item) {
    item.focus()
    item.setAttribute('data-state', 'active')
  }

  /**
   * Handle click outside
   * @param {MouseEvent} event - Click event
   */
  handleClickOutside(event) {
    if (!this.openValue) return
    
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  /**
   * Handle ESC key
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleEscape(event) {
    if (event.key === 'Escape' && this.openValue) {
      this.close()
    }
  }

  /**
   * Add event listeners
   */
  addEventListeners() {
    document.addEventListener('click', this.clickOutsideHandler)
    document.addEventListener('keydown', this.escapeHandler)
  }

  /**
   * Remove event listeners
   */
  removeEventListeners() {
    document.removeEventListener('click', this.clickOutsideHandler)
    document.removeEventListener('keydown', this.escapeHandler)
  }

  /**
   * Stop auto-updating position
   */
  stopAutoUpdate() {
    if (this.cleanupAutoUpdate) {
      this.cleanupAutoUpdate()
      this.cleanupAutoUpdate = null
    }
  }
}
