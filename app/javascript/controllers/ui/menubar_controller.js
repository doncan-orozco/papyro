import BaseController from "controllers/ui/base_controller"

/**
 * Menubar Stimulus Controller
 * 
 * Manages menubar with keyboard navigation across menu items
 * Supports multi-level menu structure and arrow key navigation
 * 
 * Usage:
 *   <div data-controller="ui--menubar" role="menubar">
 *     <button data-ui--menubar-target="trigger" 
 *             data-action="click->ui--menubar#toggleMenu keydown->ui--menubar#keydown"
 *             role="menuitem">
 *       File
 *     </button>
 *     <div data-ui--menubar-target="menu" hidden role="menu">
 *       <button data-ui--menubar-target="item" role="menuitem">New</button>
 *       <button data-ui--menubar-target="item" role="menuitem">Open</button>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether current menu is open
 * 
 * Actions:
 *   - toggleMenu: Toggle menu open/closed
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:menubar:opened
 *   - ui:menubar:closed
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false }
  }

  static targets = ["trigger", "menu", "item"]

  connect() {
    this.element.setAttribute('role', 'menubar')
    this.focusedTriggerIndex = -1
    this.focusedItemIndex = -1
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.clickOutsideHandler)
  }

  /**
   * Toggle menu open/closed
   * @param {Event} event - Click event
   */
  toggleMenu(event) {
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    if (this.triggerTargets.length === 0) return

    const currentIndex = this.focusedTriggerIndex === -1 ? 0 : this.focusedTriggerIndex

    switch (event.key) {
      case 'ArrowRight':
        event.preventDefault()
        this.focusTrigger((currentIndex + 1) % this.triggerTargets.length)
        this.openValue = true
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.focusTrigger((currentIndex - 1 + this.triggerTargets.length) % this.triggerTargets.length)
        this.openValue = true
        break
      case 'ArrowDown':
        if (this.openValue) {
          event.preventDefault()
          this.focusFirstItem()
        }
        break
      case 'Escape':
        event.preventDefault()
        this.openValue = false
        break
    }
  }

  /**
   * Update when open value changes
   */
  openValueChanged() {
    if (this.openValue) {
      document.addEventListener('click', this.clickOutsideHandler)
      
      // Show active menu
      if (this.focusedTriggerIndex >= 0 && this.menuTargets[this.focusedTriggerIndex]) {
        const menu = this.menuTargets[this.focusedTriggerIndex]
        menu.hidden = false
      }
      
      this.dispatchStateChange('ui:menubar:opened')
    } else {
      document.removeEventListener('click', this.clickOutsideHandler)
      
      // Hide all menus
      this.menuTargets.forEach(menu => {
        menu.hidden = true
      })
      
      this.dispatchStateChange('ui:menubar:closed')
    }
  }

  /**
   * Focus a menu trigger
   * @param {number} index - Trigger index
   */
  focusTrigger(index) {
    // Hide current menu
    if (this.focusedTriggerIndex >= 0 && this.menuTargets[this.focusedTriggerIndex]) {
      this.menuTargets[this.focusedTriggerIndex].hidden = true
    }

    // Focus new trigger
    this.focusedTriggerIndex = index
    this.triggerTargets[index].focus()
    
    // Show new menu
    if (this.menuTargets[index]) {
      this.menuTargets[index].hidden = false
    }
  }

  /**
   * Focus first menu item
   */
  focusFirstItem() {
    if (this.itemTargets.length > 0) {
      this.focusedItemIndex = 0
      this.itemTargets[0].focus()
    }
  }

  /**
   * Handle click outside
   * @param {MouseEvent} event - Click event
   */
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.openValue = false
    }
  }
}
