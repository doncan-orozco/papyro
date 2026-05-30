import BaseController from "controllers/ui/base_controller"

/**
 * Sonner Toast Stimulus Controller
 * 
 * Manages toast notification queue and lifecycle
 * Supports auto-dismiss, stacking, and animation
 * 
 * Usage:
 *   In your view, dispatch an event:
 *   document.dispatchEvent(new CustomEvent('sonner:show', {
 *     detail: { id: 'toast-1', message: 'Hello!', type: 'success', duration: 3000 }
 *   }))
 * 
 * Values:
 *   - maxToasts (Number): Maximum visible toasts (default: 3)
 *   - position (String): Stack position (default: "bottom-right")
 * 
 * Actions:
 *   - show: Show a toast
 *   - dismiss: Dismiss a toast
 *   - dismissAll: Dismiss all toasts
 * 
 * Events dispatched:
 *   - ui:sonner:showed - { id: string }
 *   - ui:sonner:dismissed - { id: string }
 */
export default class extends BaseController {
  static values = {
    maxToasts: { type: Number, default: 3 },
    position: { type: String, default: "bottom-right" }
  }

  static targets = ["viewport"]

  connect() {
    
    this.toasts = new Map()
    this.queue = []
    
    const container = this.toastContainer
    if (container) {
      container.setAttribute('role', 'region')
      container.setAttribute('aria-label', 'Notifications')
      container.setAttribute('aria-live', 'polite')
      container.setAttribute('aria-atomic', 'true')
    }
    
    // Listen for show events
    document.addEventListener('sonner:show', (e) => this.show(e))
    document.addEventListener('sonner:dismiss', (e) => this.dismiss(e))
  }

  disconnect() {
    document.removeEventListener('sonner:show', (e) => this.show(e))
    document.removeEventListener('sonner:dismiss', (e) => this.dismiss(e))
    
    // Clear all timeouts
    this.toasts.forEach(toast => {
      if (toast.timeout) clearTimeout(toast.timeout)
    })
  }

  /**
   * Show a demo toast (called from button click)
   * @param {Event} event - Click event
   */
  showDemo(event) {
    event?.preventDefault()

    const trigger = event?.currentTarget
    const message = trigger?.dataset?.message || 'Sonner notification example!'
    const type = trigger?.dataset?.type || 'success'
    const durationRaw = trigger?.dataset?.duration
    const duration = Number.isFinite(Number(durationRaw)) ? Number(durationRaw) : 3000
    
    const id = 'toast-' + Date.now()
    const demoEvent = {
      detail: {
        id: id,
        message,
        type,
        duration
      }
    }
    
    this.show(demoEvent)
  }

  /**
   * Show a toast
   * @param {CustomEvent} event - Sonner show event
   */
  show(event) {
    const { id, message, type = 'default', duration = 4000, action } = event.detail
    
    if (!id || !message) return


    // Create toast element
    const toast = this.createToastElement(id, message, type, action)
    
    // Store toast data
    this.toasts.set(id, {
      element: toast,
      type,
      timeout: null,
      isVisible: false
    })

    // Add to container
    this.toastContainer.appendChild(toast)
    
    // Trigger animation
    requestAnimationFrame(() => {
      toast.setAttribute('data-state', 'open')
      toast.style.opacity = '1'
      toast.style.transform = 'translateY(0)'
    })

    // Store toast as visible
    const data = this.toasts.get(id)
    data.isVisible = true

    // Set auto-dismiss timeout
    if (duration > 0) {
      data.timeout = setTimeout(() => {
        this.dismiss({ detail: { id } })
      }, duration)
    }

    this.dispatchStateChange('ui:sonner:showed', { id })
  }

  get toastContainer() {
    return this.hasViewportTarget ? this.viewportTarget : this.element
  }

  /**
   * Dismiss a toast
   * @param {CustomEvent} event - Sonner dismiss event or object with detail
   */
  dismiss(event) {
    const id = event.detail?.id
    if (!id || !this.toasts.has(id)) return


    const data = this.toasts.get(id)
    const toast = data.element

    // Clear timeout if exists
    if (data.timeout) {
      clearTimeout(data.timeout)
      data.timeout = null
    }

    // Animate out
    toast.setAttribute('data-state', 'closed')
    toast.style.opacity = '0'
    toast.style.transform = 'translateY(100%)'

    // Remove after animation
    setTimeout(() => {
      if (toast.parentNode) {
        toast.remove()
      }
      this.toasts.delete(id)
    }, 300)

    this.dispatchStateChange('ui:sonner:dismissed', { id })
  }

  /**
   * Dismiss all toasts
   * @param {Event} event - Event
   */
  dismissAll(event) {
    event?.preventDefault()
    
    const ids = Array.from(this.toasts.keys())
    ids.forEach(id => {
      this.dismiss({ detail: { id } })
    })
  }

  /**
   * Create a toast element
   * @param {string} id - Toast ID
   * @param {string} message - Toast message
   * @param {string} type - Toast type (success, error, warning, info, default)
   * @param {object} action - Optional action button
   * @returns {HTMLElement} Toast element
   */
  createToastElement(id, message, type, action) {
    const toast = document.createElement('div')
    toast.setAttribute('role', 'status')
    toast.setAttribute('aria-live', 'polite')
    toast.setAttribute('data-toast-id', id)
    toast.setAttribute('data-type', type)
    toast.setAttribute('data-state', 'closed')
    
    // Base styles
    toast.style.cssText = `
      position: relative;
      opacity: 0;
      transform: translateY(100%);
      transition: all 300ms ease-in-out;
      margin-bottom: 8px;
    `

    // Type-specific background
    const bgMap = {
      success: 'bg-green-500',
      error: 'bg-red-500',
      warning: 'bg-yellow-500',
      info: 'bg-blue-500',
      default: 'bg-gray-900'
    }

    const bgClass = bgMap[type] || bgMap.default

    // Build HTML
    toast.className = `toast ${bgClass} text-white px-4 py-3 rounded-lg shadow-lg flex items-center justify-between gap-2`
    
    // Message
    const messageEl = document.createElement('span')
    messageEl.textContent = message
    toast.appendChild(messageEl)

    // Action button if provided
    if (action) {
      const actionBtn = document.createElement('button')
      actionBtn.type = 'button'
      actionBtn.textContent = action.label || 'Action'
      actionBtn.className = 'ml-2 px-3 py-1 bg-white/20 rounded hover:bg-white/30 transition-colors text-sm'
      actionBtn.addEventListener('click', (e) => {
        if (action.onClick) action.onClick()
        this.dismiss({ detail: { id } })
      })
      toast.appendChild(actionBtn)
    }

    // Close button
    const closeBtn = document.createElement('button')
    closeBtn.type = 'button'
    closeBtn.className = 'ml-auto px-2 hover:opacity-75'
    closeBtn.innerHTML = '✕'
    closeBtn.setAttribute('aria-label', 'Close notification')
    closeBtn.addEventListener('click', () => this.dismiss({ detail: { id } }))
    toast.appendChild(closeBtn)

    return toast
  }
}
