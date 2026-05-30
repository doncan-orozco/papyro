import BaseController from "controllers/ui/base_controller"

/**
 * Tabs Stimulus Controller
 * 
 * Manages tab switching with keyboard navigation
 * Follows WAI-ARIA Tabs pattern
 * Supports horizontal and vertical orientation
 * 
 * Usage:
 *   <div data-controller="ui--tabs" data-ui--tabs-active-index-value="0">
 *     <div role="tablist">
 *       <button data-ui--tabs-target="trigger" data-action="click->ui--tabs#select">Tab 1</button>
 *       <button data-ui--tabs-target="trigger" data-action="click->ui--tabs#select">Tab 2</button>
 *     </div>
 *     <div data-ui--tabs-target="content">Content 1</div>
 *     <div data-ui--tabs-target="content">Content 2</div>
 *   </div>
 * 
 * Values:
 *   - activeIndex (Number): Currently active tab index
 *   - orientation (String): "horizontal" or "vertical" for keyboard navigation
 * 
 * Actions:
 *   - select: Select a tab (click)
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:tabs:changed - { index: number, previousIndex: number }
 */
export default class extends BaseController {
  static values = {
    activeIndex: { type: Number, default: 0 },
    orientation: { type: String, default: "horizontal" }
  }

  static targets = ["trigger", "content"]

  connect() {
    // Ensure active index is valid
    if (this.activeIndexValue < 0 || this.activeIndexValue >= this.triggerTargets.length) {
      this.activeIndexValue = 0
    }
    
    // Initialize state
    this.updateTabs()
  }

  /**
   * Select a tab
   * @param {Event} event - Click event
   */
  select(event) {
    const trigger = event.currentTarget
    const index = this.triggerTargets.indexOf(trigger)
    
    if (index === -1 || index === this.activeIndexValue) return

    const previousIndex = this.activeIndexValue
    this.activeIndexValue = index
    
    this.dispatchStateChange("ui:tabs:changed", {
      index,
      previousIndex
    })
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    const trigger = event.target
    if (!this.triggerTargets.includes(trigger)) return

    const currentIndex = this.triggerTargets.indexOf(trigger)
    let targetIndex = currentIndex

    // Determine navigation keys based on orientation
    const nextKey = this.orientationValue === "vertical" ? "ArrowDown" : "ArrowRight"
    const prevKey = this.orientationValue === "vertical" ? "ArrowUp" : "ArrowLeft"

    switch (event.key) {
      case nextKey:
        event.preventDefault()
        targetIndex = this.getCircularIndex(currentIndex, this.triggerTargets.length, 1)
        break
      case prevKey:
        event.preventDefault()
        targetIndex = this.getCircularIndex(currentIndex, this.triggerTargets.length, -1)
        break
      case 'Home':
        event.preventDefault()
        targetIndex = 0
        break
      case 'End':
        event.preventDefault()
        targetIndex = this.triggerTargets.length - 1
        break
      default:
        return
    }

    if (targetIndex !== currentIndex) {
      this.activeIndexValue = targetIndex
      this.triggerTargets[targetIndex].focus()
    }
  }

  /**
   * Update when active index changes
   */
  activeIndexValueChanged() {
    this.updateTabs()
  }

  /**
   * Update all tabs and panels state
   */
  updateTabs() {
    this.triggerTargets.forEach((trigger, index) => {
      const content = this.contentTargets[index]
      const isActive = index === this.activeIndexValue

      // Update trigger state
      trigger.setAttribute("data-state", isActive ? "active" : "inactive")
      trigger.setAttribute("aria-selected", isActive.toString())
      trigger.setAttribute("tabindex", isActive ? "0" : "-1")
      
      // Set ARIA controls (if content has ID)
      if (content?.id) {
        trigger.setAttribute("aria-controls", content.id)
        trigger.id = trigger.id || `${content.id}-trigger`
      }

      // Update content state
      if (content) {
        content.setAttribute("data-state", isActive ? "active" : "inactive")
        content.hidden = !isActive
        
        // Set ARIA labelledby (if trigger has ID)
        if (trigger.id) {
          content.setAttribute("aria-labelledby", trigger.id)
        }
      }
    })
  }
}
