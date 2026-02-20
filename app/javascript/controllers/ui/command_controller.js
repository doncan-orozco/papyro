import BaseController from "controllers/ui/base_controller"

/**
 * Command Stimulus Controller
 * 
 * Manages command/search interface with filtering, keyboard navigation
 * Typically used for command palettes, search dropdowns, or command menus
 * 
 * Usage:
 *   <div data-controller="ui--command" 
 *        data-ui--command-open-value="false"
 *        data-ui--command-filter-value="">
 *     <input type="text" 
 *            placeholder="Search..." 
 *            data-ui--command-target="input"
 *            data-action="input->ui--command#filter focus->ui--command#open keydown->ui--command#keydown" />
 *     <div data-ui--command-target="list">
 *       <button class="command-item" data-ui--command-target="item" data-action="click->ui--command#selectItem">
 *         Item 1
 *       </button>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - open (Boolean): Whether command is open (default: false)
 *   - filter (String): Current filter text
 * 
 * Actions:
 *   - filter: Handle input filtering
 *   - open: Open the command
 *   - close: Close the command
 *   - keydown: Handle keyboard navigation
 *   - selectItem: Select a command item
 * 
 * Events dispatched:
 *   - ui:command:opened
 *   - ui:command:closed
 *   - ui:command:filtered - { query: string, count: number }
 *   - ui:command:selected - { item: HTMLElement, value: string }
 */
export default class extends BaseController {
  static values = {
    open: { type: Boolean, default: false },
    filter: String
  }

  static targets = ["input", "list", "item"]

  connect() {
    console.log('⌘ Command controller connected', this.element)
    this.focusedItemIndex = -1
    this.escapeHandler = this.handleEscape.bind(this)
  }

  disconnect() {
    this.removeEventListeners()
  }

  /**
   * Open the command
   * @param {Event} event - Focus event
   */
  open(event) {
    event?.preventDefault()
    this.openValue = true
  }

  /**
   * Close the command
   * @param {Event} event - Event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
    this.focusedItemIndex = -1
  }

  /**
   * Handle input filtering
   * @param {Event} event - Input event
   */
  filter(event) {
    const query = event.target.value
    this.filterValue = query
    
    if (!this.hasListTarget || !this.hasItemTargets) return

    console.log('⌘ Command filter:', query)

    const lowerQuery = query.toLowerCase()
    let visibleCount = 0

    // Filter items based on query
    this.itemTargets.forEach((item, index) => {
      const text = item.textContent.toLowerCase()
      const isVisible = text.includes(lowerQuery)
      
      item.style.display = isVisible ? 'block' : 'none'
      item.setAttribute('data-filtered', isVisible ? 'true' : 'false')
      
      if (isVisible) {
        visibleCount++
      }
    })

    // Reset focused item
    this.focusedItemIndex = -1

    // Dispatch filter event
    this.dispatchStateChange('ui:command:filtered', {
      query,
      count: visibleCount
    })
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    if (!this.openValue) return

    const visibleItems = this.getVisibleItems()
    if (visibleItems.length === 0) return

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.focusNextItem(visibleItems)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.focusPreviousItem(visibleItems)
        break
      case 'Home':
        event.preventDefault()
        this.focusFirstItem(visibleItems)
        break
      case 'End':
        event.preventDefault()
        this.focusLastItem(visibleItems)
        break
      case 'Enter':
        event.preventDefault()
        if (this.focusedItemIndex >= 0) {
          this.selectItem({ currentTarget: visibleItems[this.focusedItemIndex] })
        }
        break
      case 'Escape':
        event.preventDefault()
        this.close()
        break
    }
  }

  /**
   * Select a command item
   * @param {Event} event - Click event
   */
  selectItem(event) {
    const item = event.currentTarget
    
    // Dispatch selection event
    this.dispatchStateChange('ui:command:selected', {
      item,
      value: item.textContent
    })
    
    // Close command after selection
    this.close()
  }

  /**
   * Update when open value changes
   */
  openValueChanged() {
    if (this.openValue) {
      this.addEventListeners()
      
      // Focus input
      if (this.hasInputTarget) {
        this.inputTarget.focus()
      }
      
      this.dispatchStateChange('ui:command:opened')
    } else {
      this.removeEventListeners()
      this.dispatchStateChange('ui:command:closed')
    }
  }

  /**
   * Get visible (non-filtered) items
   * @returns {HTMLElement[]} Visible items
   */
  getVisibleItems() {
    return this.itemTargets.filter(
      item => item.getAttribute('data-filtered') !== 'false' && item.style.display !== 'none'
    )
  }

  /**
   * Focus next item
   * @param {HTMLElement[]} items - Visible items
   */
  focusNextItem(items) {
    this.focusedItemIndex = Math.min(this.focusedItemIndex + 1, items.length - 1)
    this.focusItem(items[this.focusedItemIndex])
  }

  /**
   * Focus previous item
   * @param {HTMLElement[]} items - Visible items
   */
  focusPreviousItem(items) {
    this.focusedItemIndex = Math.max(this.focusedItemIndex - 1, 0)
    this.focusItem(items[this.focusedItemIndex])
  }

  /**
   * Focus first item
   * @param {HTMLElement[]} items - Visible items
   */
  focusFirstItem(items) {
    if (items.length > 0) {
      this.focusedItemIndex = 0
      this.focusItem(items[0])
    }
  }

  /**
   * Focus last item
   * @param {HTMLElement[]} items - Visible items
   */
  focusLastItem(items) {
    if (items.length > 0) {
      this.focusedItemIndex = items.length - 1
      this.focusItem(items[this.focusedItemIndex])
    }
  }

  /**
   * Focus an item
   * @param {HTMLElement} item - Item to focus
   */
  focusItem(item) {
    // Clear previous highlight
    this.itemTargets.forEach(i => {
      i.setAttribute('data-state', 'inactive')
    })

    // Highlight focused item
    item.setAttribute('data-state', 'active')
    item.scrollIntoView({ block: 'nearest' })
  }

  /**
   * Add event listeners
   */
  addEventListeners() {
    document.addEventListener('keydown', this.escapeHandler)
  }

  /**
   * Remove event listeners
   */
  removeEventListeners() {
    document.removeEventListener('keydown', this.escapeHandler)
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
}
