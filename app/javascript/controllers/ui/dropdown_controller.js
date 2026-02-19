import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset } from "@floating-ui/dom"

/**
 * Dropdown Menu Stimulus Controller
 * 
 * Manages dropdown menu with keyboard navigation and smart positioning
 * Follows WAI-ARIA Menu pattern
 * Uses Floating UI for dynamic positioning
 * 
 * Usage:
 *   <div data-controller="ui--dropdown" data-ui--dropdown-placement-value="bottom-start">
 *     <button data-ui--dropdown-target="trigger" 
 *             data-action="click->ui--dropdown#toggle">
 *       Menu
 *     </button>
 *     <div data-ui--dropdown-target="content" role="menu" hidden>
 *       <button data-ui--dropdown-target="item" role="menuitem">Item 1</button>
 *       <button data-ui--dropdown-target="item" role="menuitem">Item 2</button>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether dropdown is open
 *   - placement (String): Preferred position (default: "bottom-start")
 *   - offset (Number): Distance from trigger in pixels (default: 4)
 * 
 * Actions:
 *   - toggle: Toggle dropdown open/closed
 *   - close: Close dropdown
 *   - navigate: Navigate with arrow keys
 *   - select: Select item with Enter/Space
 * 
 * Events dispatched:
 *   - ui:dropdown:opened
 *   - ui:dropdown:closed
 *   - ui:dropdown:selected - { item: HTMLElement }
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false },
    placement: { type: String, default: "bottom-start" },
    offset: { type: Number, default: 4 }
  }

  static targets = ["trigger", "content", "item"]

  connect() {
    console.log('📋 Dropdown controller connected', this.element)
    this.focusedItemIndex = -1
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    this.escapeHandler = this.handleEscape.bind(this)
    
    // Setup content
    if (this.hasContentTarget) {
      this.contentTarget.hidden = true
      this.contentTarget.style.position = 'absolute'
    }
    
    // Setup trigger ARIA
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-haspopup', 'menu')
      this.triggerTarget.setAttribute('aria-expanded', 'false')
    }
  }

  disconnect() {
    this.removeEventListeners()
    this.stopAutoUpdate()
  }

  /**
   * Toggle dropdown open/closed
   * @param {Event} event - Click event
   */
  toggle(event) {
    console.log('📋 Dropdown toggle clicked', { open: this.openValue })
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  /**
   * Close dropdown
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
   * Handle item selection
   * @param {Event} event - Click or keyboard event
   */
  select(event) {
    const item = event.currentTarget
    
    // Dispatch selection event
    this.dispatchStateChange("ui:dropdown:selected", { item })
    
    // Close dropdown after selection
    this.close()
  }

  /**
   * Handle keydown on items
   * @param {KeyboardEvent} event - Keyboard event
   */
  itemKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.select(event)
    } else {
      this.navigate(event)
    }
  }

  /**
   * Update when open value changes
   */
  async openValueChanged() {
    if (this.openValue) {
      await this.openDropdown()
    } else {
      this.closeDropdown()
    }
  }

  /**
   * Open the dropdown
   */
  async openDropdown() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    // Show content
    this.contentTarget.hidden = false
    this.contentTarget.style.opacity = '0'
    
    // Update trigger ARIA
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    
    // Position dropdown
    await this.updatePosition()
    
    // Fade in
    this.contentTarget.style.opacity = '1'
    
    // Focus first item
    const items = this.getNavigableItems()
    if (items.length > 0) {
      this.focusItem(items[0])
      this.focusedItemIndex = 0
    }
    
    // Start auto-updating position
    this.startAutoUpdate()
    
    // Add event listeners
    this.addEventListeners()
    
    this.dispatchStateChange("ui:dropdown:opened")
  }

  /**
   * Close the dropdown
   */
  closeDropdown() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    // Hide content
    this.contentTarget.hidden = true
    this.contentTarget.style.opacity = '0'
    
    // Update trigger ARIA
    this.triggerTarget.setAttribute('aria-expanded', 'false')
    
    // Return focus to trigger
    this.triggerTarget.focus()
    
    // Reset focus index
    this.focusedItemIndex = -1
    
    // Stop auto-updating
    this.stopAutoUpdate()
    
    // Remove event listeners
    this.removeEventListeners()
    
    this.dispatchStateChange("ui:dropdown:closed")
  }

  /**
   * Update dropdown position using Floating UI
   */
  async updatePosition() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    const { x, y } = await computePosition(
      this.triggerTarget,
      this.contentTarget,
      {
        placement: this.placementValue,
        middleware: [
          offset(this.offsetValue),
          flip(),
          shift({ padding: 5 })
        ]
      }
    )

    Object.assign(this.contentTarget.style, {
      left: `${x}px`,
      top: `${y}px`
    })
  }

  /**
   * Get navigable menu items (skip labels, separators)
   */
  getNavigableItems() {
    return this.itemTargets.filter(item => {
      const role = item.getAttribute('role')
      return role === 'menuitem' && !item.disabled && !item.hasAttribute('disabled')
    })
  }

  /**
   * Focus next item
   * @param {Array<HTMLElement>} items - Navigable items
   */
  focusNextItem(items) {
    const nextIndex = this.getCircularIndex(this.focusedItemIndex, items.length, 1)
    this.focusItem(items[nextIndex])
    this.focusedItemIndex = nextIndex
  }

  /**
   * Focus previous item
   * @param {Array<HTMLElement>} items - Navigable items
   */
  focusPreviousItem(items) {
    const prevIndex = this.getCircularIndex(this.focusedItemIndex, items.length, -1)
    this.focusItem(items[prevIndex])
    this.focusedItemIndex = prevIndex
  }

  /**
   * Focus first item
   * @param {Array<HTMLElement>} items - Navigable items
   */
  focusFirstItem(items) {
    this.focusItem(items[0])
    this.focusedItemIndex = 0
  }

  /**
   * Focus last item
   * @param {Array<HTMLElement>} items - Navigable items
   */
  focusLastItem(items) {
    const lastIndex = items.length - 1
    this.focusItem(items[lastIndex])
    this.focusedItemIndex = lastIndex
  }

  /**
   * Focus a specific item
   * @param {HTMLElement} item - Item to focus
   */
  focusItem(item) {
    if (!item) return
    item.focus()
  }

  /**
   * Start auto-updating position on scroll/resize
   */
  startAutoUpdate() {
    this.updatePositionBound = this.updatePosition.bind(this)
    window.addEventListener('scroll', this.updatePositionBound, true)
    window.addEventListener('resize', this.updatePositionBound)
  }

  /**
   * Stop auto-updating position
   */
  stopAutoUpdate() {
    if (this.updatePositionBound) {
      window.removeEventListener('scroll', this.updatePositionBound, true)
      window.removeEventListener('resize', this.updatePositionBound)
      this.updatePositionBound = null
    }
  }

  /**
   * Add event listeners for outside click and escape
   */
  addEventListeners() {
    // Delay to avoid immediate close from trigger click
    setTimeout(() => {
      document.addEventListener('click', this.clickOutsideHandler)
      document.addEventListener('keydown', this.escapeHandler)
    }, 0)
  }

  /**
   * Remove event listeners
   */
  removeEventListeners() {
    document.removeEventListener('click', this.clickOutsideHandler)
    document.removeEventListener('keydown', this.escapeHandler)
  }

  /**
   * Handle click outside dropdown
   * @param {MouseEvent} event - Click event
   */
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  /**
   * Handle escape key
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}
