import BaseController from "controllers/ui/base_controller"
import { computePosition, flip, shift, offset } from "@floating-ui/dom"

/**
 * Date Picker Stimulus Controller
 * 
 * Manages date picker with calendar popup and input integration
 * Opens calendar in popover when input is focused
 * 
 * Usage:
 *   <div data-controller="ui--date-picker" data-ui--date-picker-value-value="2024-01-15">
 *     <input type="text" 
 *            placeholder="Pick a date..." 
 *            data-ui--date-picker-target="input"
 *            data-action="focus->ui--date-picker#open" 
 *            readonly />
 *     <div data-ui--date-picker-target="calendar" hidden>
 *       <div data-ui--date-picker-target="days"></div>
 *     </div>
 *   </div>
 * 
 * Values:
 *   - value (String): Selected date (YYYY-MM-DD format)
 *   - month (Number): Calendar month (0-11)
 *   - year (Number): Calendar year
 *   - open (Boolean): Whether calendar is open
 * 
 * Actions:
 *   - open: Open calendar
 *   - close: Close calendar
 *   - selectDate: Select a date
 * 
 * Events dispatched:
 *   - ui:date-picker:changed - { date: string }
 *   - ui:date-picker:opened
 *   - ui:date-picker:closed
 */
export default class extends BaseController {
  static values = {
    value: String,
    month: { type: Number, default: new Date().getMonth() },
    year: { type: Number, default: new Date().getFullYear() },
    open: { type: Boolean, default: false }
  }

  static targets = ["input", "calendar", "days"]

  connect() {
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    this.cleanupAutoUpdate = null
    
    // Setup calendar
    if (this.hasCalendarTarget) {
      this.calendarTarget.style.position = 'absolute'
      this.calendarTarget.style.zIndex = '1000'
      this.calendarTarget.hidden = true
    }

    // Format initial value in input if exists
    if (this.hasValueValue && this.hasInputTarget) {
      this.inputTarget.value = this.formatDisplayDate(this.valueValue)
    }

    // Render calendar
    this.renderCalendar()
  }

  disconnect() {
    this.removeEventListeners()
    this.stopAutoUpdate()
  }

  /**
   * Open the date picker
   * @param {Event} event - Focus event
   */
  open(event) {
    event?.preventDefault()
    this.openValue = true
  }

  /**
   * Close the date picker
   * @param {Event} event - Event
   */
  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  /**
   * Select a date
   * @param {Event} event - Click event
   */
  selectDate(event) {
    const date = event.currentTarget.getAttribute('data-date')
    if (date) {
      this.valueValue = date
      
      // Update input
      if (this.hasInputTarget) {
        this.inputTarget.value = this.formatDisplayDate(date)
      }
      
      this.close()
      this.dispatchStateChange('ui:date-picker:changed', { date })
    }
  }

  /**
   * Update when open value changes
   */
  async openValueChanged() {
    if (this.openValue) {
      await this.openCalendar()
    } else {
      this.closeCalendar()
    }
  }

  /**
   * Open calendar popover
   */
  async openCalendar() {
    if (!this.hasCalendarTarget || !this.hasInputTarget) return

    // Show calendar
    this.calendarTarget.hidden = false
    this.calendarTarget.style.opacity = '0'

    // Position calendar
    await this.updatePosition()

    // Fade in
    requestAnimationFrame(() => {
      this.calendarTarget.style.opacity = '1'
    })

    // Start auto-updating position
    this.startAutoUpdate()

    // Add event listeners
    this.addEventListeners()

    this.dispatchStateChange('ui:date-picker:opened')
  }

  /**
   * Close calendar popover
   */
  closeCalendar() {
    if (!this.hasCalendarTarget) return

    this.calendarTarget.style.opacity = '0'
    
    setTimeout(() => {
      if (this.hasCalendarTarget) {
        this.calendarTarget.hidden = true
      }
    }, 150)

    // Stop auto-updating position
    this.stopAutoUpdate()

    // Remove event listeners
    this.removeEventListeners()

    this.dispatchStateChange('ui:date-picker:closed')
  }

  /**
   * Update calendar position using Floating UI
   */
  async updatePosition() {
    if (!this.hasCalendarTarget || !this.hasInputTarget) return

    const { x, y } = await computePosition(
      this.inputTarget,
      this.calendarTarget,
      {
        placement: 'bottom-start',
        middleware: [
          flip(),
          shift({ padding: 8 }),
          offset(4)
        ]
      }
    )

    this.calendarTarget.style.left = `${x}px`
    this.calendarTarget.style.top = `${y}px`
  }

  /**
   * Start auto-updating position during scroll/resize
   */
  startAutoUpdate() {
    if (this.cleanupAutoUpdate) return

    const update = async () => {
      await this.updatePosition()
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
   * Render the calendar
   */
  renderCalendar() {
    if (!this.hasDaysTarget) return

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ]

    const firstDay = new Date(this.yearValue, this.monthValue, 1).getDay()
    const daysInMonth = new Date(this.yearValue, this.monthValue + 1, 0).getDate()
    const daysInPrevMonth = new Date(this.yearValue, this.monthValue, 0).getDate()

    // Clear existing days
    this.daysTarget.innerHTML = ''

    // Add previous month's trailing days
    for (let i = firstDay - 1; i >= 0; i--) {
      const day = daysInPrevMonth - i
      const button = this.createDayButton(day, true)
      this.daysTarget.appendChild(button)
    }

    // Add current month's days
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(this.yearValue, this.monthValue, day)
      const dateStr = this.formatDate(date)
      const button = this.createDayButton(day, false)
      
      button.setAttribute('data-date', dateStr)
      
      // Mark as selected if matches value
      if (this.hasValueValue && this.valueValue === dateStr) {
        button.classList.add('selected')
        button.setAttribute('data-state', 'selected')
      }
      
      button.addEventListener('click', (e) => this.selectDate(e))
      this.daysTarget.appendChild(button)
    }

    // Add next month's leading days
    const totalCells = this.daysTarget.children.length
    const remainingCells = 42 - totalCells
    for (let day = 1; day <= remainingCells; day++) {
      const button = this.createDayButton(day, true)
      this.daysTarget.appendChild(button)
    }
  }

  /**
   * Create a day button
   * @param {number} day - Day number
   * @param {boolean} isDisabled - Whether button is disabled
   * @returns {HTMLElement} Button element
   */
  createDayButton(day, isDisabled) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'p-2 text-sm rounded hover:bg-accent'
    button.textContent = day
    
    if (isDisabled) {
      button.disabled = true
      button.setAttribute('data-state', 'disabled')
      button.style.opacity = '0.5'
      button.style.cursor = 'default'
    }
    
    return button
  }

  /**
   * Format date as ISO string (YYYY-MM-DD)
   * @param {Date} date - Date object
   * @returns {string} Formatted date
   */
  formatDate(date) {
    return date.toISOString().split('T')[0]
  }

  /**
   * Format date for display in input
   * @param {string} dateStr - ISO date string
   * @returns {string} Formatted date for display
   */
  formatDisplayDate(dateStr) {
    if (!dateStr) return ''
    
    const date = new Date(dateStr + 'T00:00:00')
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
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
   * Add event listeners
   */
  addEventListeners() {
    document.addEventListener('click', this.clickOutsideHandler)
  }

  /**
   * Remove event listeners
   */
  removeEventListeners() {
    document.removeEventListener('click', this.clickOutsideHandler)
  }
}
