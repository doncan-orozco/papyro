import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset } from "@floating-ui/dom"

/**
 * Navigation Menu Stimulus Controller
 * 
 * Manages multi-level navigation menu with hover/focus states
 * Supports keyboard navigation and smart submenu positioning
 * 
 * Usage:
 *   <nav data-controller="ui--navigation-menu">
 *     <a href="#" data-ui--navigation-menu-target="trigger" 
 *        data-action="mouseenter->ui--navigation-menu#showSubmenu mouseleave->ui--navigation-menu#hideSubmenu">
 *       Products
 *     </a>
 *     <div data-ui--navigation-menu-target="submenu" hidden>
 *       <a href="/products/1">Product 1</a>
 *       <a href="/products/2">Product 2</a>
 *     </div>
 *   </nav>
 * 
 * Values:
 *   - activeIndex (Number): Currently active menu item
 * 
 * Actions:
 *   - showSubmenu: Show submenu on hover
 *   - hideSubmenu: Hide submenu on mouse leave
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:navigation-menu:opened - { index: number }
 *   - ui:navigation-menu:closed - { index: number }
 */
export default class extends BaseController {
  static values = {
    activeIndex: { type: Number, default: -1 }
  }

  static targets = ["trigger", "submenu"]

  connect() {
    console.log('🧭 Navigation Menu controller connected', this.element)
    this.element.setAttribute('role', 'navigation')
    this.hoverTimeout = null
    this.cleanupAutoUpdate = null
    
    // Setup triggers
    this.triggerTargets.forEach((trigger, index) => {
      trigger.setAttribute('role', 'button')
      trigger.setAttribute('aria-expanded', 'false')
      trigger.addEventListener('keydown', (e) => this.keydown(e, index))
    })

    // Setup submenus
    this.submenuTargets.forEach(submenu => {
      submenu.style.position = 'absolute'
      submenu.style.zIndex = '1000'
      submenu.hidden = true
      submenu.style.opacity = '0'
    })
  }

  disconnect() {
    this.clearHoverTimeout()
    this.stopAutoUpdate()
  }

  /**
   * Show submenu on hover
   * @param {Event} event - Mouseenter event
   */
  showSubmenu(event) {
    const trigger = event.currentTarget
    const index = this.triggerTargets.indexOf(trigger)
    
    if (index === -1) return

    // Clear any pending hide
    this.clearHoverTimeout()

    // Show submenu after delay
    this.hoverTimeout = setTimeout(() => {
      this.activeIndexValue = index
    }, 100)
  }

  /**
   * Hide submenu on mouse leave
   * @param {Event} event - Mouseleave event
   */
  hideSubmenu(event) {
    this.clearHoverTimeout()

    // Delay hiding to allow moving to submenu
    this.hoverTimeout = setTimeout(() => {
      this.activeIndexValue = -1
    }, 150)
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   * @param {number} index - Trigger index
   */
  keydown(event, index) {
    switch (event.key) {
      case 'ArrowRight':
        event.preventDefault()
        this.focusTrigger((index + 1) % this.triggerTargets.length)
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.focusTrigger((index - 1 + this.triggerTargets.length) % this.triggerTargets.length)
        break
      case 'ArrowDown':
        event.preventDefault()
        this.activeIndexValue = index
        break
      case 'Escape':
        event.preventDefault()
        this.activeIndexValue = -1
        break
    }
  }

  /**
   * Focus a trigger
   * @param {number} index - Trigger index
   */
  focusTrigger(index) {
    if (this.triggerTargets[index]) {
      this.triggerTargets[index].focus()
      this.activeIndexValue = index
    }
  }

  /**
   * Update when activeIndex changes
   */
  activeIndexValueChanged() {
    this.updateMenus()
  }

  /**
   * Update menu visibility
   */
  async updateMenus() {
    for (let i = 0; i < this.submenuTargets.length; i++) {
      const isActive = i === this.activeIndexValue
      const submenu = this.submenuTargets[i]
      const trigger = this.triggerTargets[i]

      if (isActive) {
        submenu.hidden = false
        trigger.setAttribute('aria-expanded', 'true')
        
        // Position submenu
        await this.updatePosition(i)
        
        // Fade in
        requestAnimationFrame(() => {
          submenu.style.opacity = '1'
        })

        // Start auto-updating position
        this.startAutoUpdate()

        this.dispatchStateChange('ui:navigation-menu:opened', { index: i })
      } else {
        submenu.style.opacity = '0'
        trigger.setAttribute('aria-expanded', 'false')
        
        setTimeout(() => {
          if (submenu.hidden !== true && i !== this.activeIndexValue) {
            submenu.hidden = true
          }
        }, 150)

        this.dispatchStateChange('ui:navigation-menu:closed', { index: i })
      }
    }
  }

  /**
   * Update submenu position
   * @param {number} index - Submenu index
   */
  async updatePosition(index) {
    const trigger = this.triggerTargets[index]
    const submenu = this.submenuTargets[index]

    if (!trigger || !submenu) return

    const { x, y } = await computePosition(
      trigger,
      submenu,
      {
        placement: 'bottom-start',
        middleware: [
          flip(),
          shift({ padding: 8 }),
          offset(4)
        ]
      }
    )

    submenu.style.left = `${x}px`
    submenu.style.top = `${y}px`
  }

  /**
   * Start auto-updating position during scroll/resize
   */
  startAutoUpdate() {
    if (this.cleanupAutoUpdate) return

    const update = async () => {
      if (this.activeIndexValue >= 0) {
        await this.updatePosition(this.activeIndexValue)
      }
    }

    window.addEventListener('scroll', update, true)
    window.addEventListener('resize', update)

    this.cleanupAutoUpdate = () => {
      window.removeEventListener('scroll', update, true)
      window.removeEventListener('resize', update)
    }
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
   * Clear hover timeout
   */
  clearHoverTimeout() {
    if (this.hoverTimeout) {
      clearTimeout(this.hoverTimeout)
      this.hoverTimeout = null
    }
  }
}
