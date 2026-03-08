import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset, autoUpdate } from "@floating-ui/dom"

/**
 * Select Stimulus Controller
 * 
 * Custom select dropdown with keyboard navigation and smart positioning
 * Follows WAI-ARIA Listbox pattern
 * Uses Floating UI for dynamic positioning
 * 
 * Usage:
 *   <div data-controller="ui--select" 
 *        data-ui--select-value-value="apple"
 *        data-ui--select-placeholder-value="Select an option">
 *     <button data-ui--select-target="trigger" 
 *             data-action="click->ui--select#toggle">
 *       <span data-ui--select-target="valueDisplay"></span>
 *       <svg>chevron</svg>
 *     </button>
 *     <div data-ui--select-target="content" role="listbox" hidden>
 *       <div data-ui--select-target="item" 
 *            data-value="apple" 
 *            role="option">Apple</div>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - value (String): Currently selected value
 *   - placeholder (String): Placeholder text
 *   - placement (String): Preferred position (default: "bottom-start")
 *   - offset (Number): Distance from trigger (default: 4)
 * 
 * Actions:
 *   - toggle: Toggle dropdown open/closed
 *   - selectItem: Select an item
 * 
 * Events dispatched:
 *   - ui:select:change - { value: String, text: String }
 */
export default class extends BaseController {
  static values = {
    value: { type: String, default: "" },
    placeholder: { type: String, default: "Select an option" },
    placement: { type: String, default: "bottom-start" },
    offset: { type: Number, default: 4 }
  }

  static targets = ["trigger", "content", "item", "valueDisplay"]

  connect() {
    console.log('🎯  Select controller connected', this.element)
    this.isOpen = false
    this.focusedItemIndex = -1
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    this.escapeHandler = this.handleEscape.bind(this)
    this.cleanupAutoUpdate = null
    
    // Setup content
    if (this.hasContentTarget) {
      this.contentTarget.hidden = true
      this.contentTarget.style.position = 'fixed'
      this.contentTarget.style.visibility = 'hidden'
    }
    
    // Initialize display
    this.updateDisplay()
    this.updateItemStates()
  }

  disconnect() {
    this.removeEventListeners()
    this.stopAutoUpdate()
    this.restoreBodyScroll()
  }

  /**
   * Toggle dropdown open/closed
   */
  toggle(event) {
    event?.preventDefault()
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  /**
   * Open the dropdown
   */
  async open() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    this.isOpen = true

    // Disable transitions during position calculation
    this.contentTarget.style.transition = 'none'
    this.contentTarget.style.visibility = 'hidden'
    this.contentTarget.style.opacity = '0'
    this.contentTarget.hidden = false
    
    // Update trigger ARIA
    this.triggerTarget.setAttribute('aria-expanded', 'true')
    
    // Calculate position
    await this.updatePosition()
    
    // Enable opacity transition and show
    this.contentTarget.style.transition = 'opacity 200ms'
    this.contentTarget.style.visibility = 'visible'
    // Force reflow
    this.contentTarget.offsetHeight
    this.contentTarget.style.opacity = '1'
    
    // Focus selected item or first item
    const items = this.getNavigableItems()
    const selectedIndex = this.getSelectedItemIndex(items)
    if (selectedIndex !== -1) {
      this.focusItem(items[selectedIndex])
      this.focusedItemIndex = selectedIndex
    } else if (items.length > 0) {
      this.focusItem(items[0])
      this.focusedItemIndex = 0
    }
    
    // Start auto-updating position
    this.startAutoUpdate()
    
    // Add event listeners
    this.addEventListeners()

    // Prevent body scroll
    this.preventBodyScroll()
  }

  /**
   * Close the dropdown
   */
  close() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    // Hide content
    this.contentTarget.hidden = true
    this.contentTarget.style.opacity = '0'
    this.contentTarget.style.visibility = 'hidden'
    this.contentTarget.style.transition = ''
    
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

    // Restore body scroll
    this.restoreBodyScroll()
    
    this.isOpen = false
  }

  /**
   * Select an item
   */
  selectItem(event) {
    const item = event.currentTarget
    const value = item.dataset.value
    const text = this.getItemText(item)
    
    // Update value
    this.valueValue = value
    
    // Update display and states
    this.updateDisplay()
    this.updateItemStates()
    
    // Dispatch change event
    this.dispatch("change", { detail: { value, text } })
    
    // Close dropdown
    this.close()
  }

  /**
   * Handle keyboard navigation
   */
  navigate(event) {
    if (!this.isOpen) return

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
      case 'Enter':
      case ' ':
        event.preventDefault()
        if (this.focusedItemIndex !== -1) {
          items[this.focusedItemIndex].click()
        }
        break
      case 'Escape':
        event.preventDefault()
        this.close()
        break
    }
  }

  /**
   * Update position using Floating UI
   */
  async updatePosition() {
    if (!this.hasContentTarget || !this.hasTriggerTarget) return

    // Disable transitions during position update
    const currentTransition = this.contentTarget.style.transition
    this.contentTarget.style.transition = 'none'

    const { x, y } = await computePosition(
      this.triggerTarget,
      this.contentTarget,
      {
        strategy: 'fixed',
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

    // Restore transition
    if (currentTransition) {
      this.contentTarget.offsetHeight
      this.contentTarget.style.transition = currentTransition
    }
  }

  /**
   * Start auto-updating position on scroll/resize
   */
  startAutoUpdate() {
    if (this.cleanupAutoUpdate) return
    
    this.cleanupAutoUpdate = autoUpdate(
      this.triggerTarget,
      this.contentTarget,
      () => this.updatePosition()
    )
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

  /**
   * Update the trigger display with selected value
   */
  updateDisplay() {
    if (!this.hasValueDisplayTarget) return

    const selectedItem = this.itemTargets.find(
      item => item.dataset.value === this.valueValue
    )

    if (selectedItem) {
      this.valueDisplayTarget.textContent = this.getItemText(selectedItem)
      this.valueDisplayTarget.classList.remove('text-muted-foreground')
    } else {
      this.valueDisplayTarget.textContent = this.placeholderValue
      this.valueDisplayTarget.classList.add('text-muted-foreground')
    }
  }

  /**
   * Update selected state on all items
   */
  updateItemStates() {
    this.itemTargets.forEach(item => {
      const isSelected = item.dataset.value === this.valueValue
      item.dataset.selected = isSelected
      item.setAttribute('aria-selected', isSelected)
      
      // Update checkmark visibility
      const checkmark = item.querySelector('[data-ui--select-checkmark]')
      if (checkmark) {
        if (isSelected) {
          checkmark.dataset.selected = 'true'
        } else {
          delete checkmark.dataset.selected
        }
      }
    })
  }

  /**
   * Get plain label text from an item (ignores checkmark icon container)
   */
  getItemText(item) {
    if (!item) return ''

    const label = item.querySelector('span:last-child')
    return label ? label.textContent.trim() : item.textContent.trim()
  }

  /**
   * Get navigable items
   */
  getNavigableItems() {
    return this.itemTargets.filter(item => {
      return !item.disabled && !item.hasAttribute('disabled')
    })
  }

  /**
   * Get index of selected item
   */
  getSelectedItemIndex(items) {
    return items.findIndex(item => item.dataset.value === this.valueValue)
  }

  /**
   * Focus an item
   */
  focusItem(item) {
    item.focus()
    item.scrollIntoView({ block: 'nearest' })
  }

  /**
   * Focus next item
   */
  focusNextItem(items) {
    const nextIndex = this.getCircularIndex(this.focusedItemIndex, items.length, 1)
    this.focusItem(items[nextIndex])
    this.focusedItemIndex = nextIndex
  }

  /**
   * Focus previous item
   */
  focusPreviousItem(items) {
    const prevIndex = this.getCircularIndex(this.focusedItemIndex, items.length, -1)
    this.focusItem(items[prevIndex])
    this.focusedItemIndex = prevIndex
  }

  /**
   * Focus first item
   */
  focusFirstItem(items) {
    this.focusItem(items[0])
    this.focusedItemIndex = 0
  }

  /**
   * Focus last item
   */
  focusLastItem(items) {
    const lastIndex = items.length - 1
    this.focusItem(items[lastIndex])
    this.focusedItemIndex = lastIndex
  }

  /**
   * Get circular index for wrapping navigation
   */
  getCircularIndex(current, length, direction) {
    return (current + direction + length) % length
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
   * Handle click outside
   */
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  /**
   * Handle escape key
   */
  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}
