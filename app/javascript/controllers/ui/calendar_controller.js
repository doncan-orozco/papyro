import BaseController from "controllers/ui/base_controller"

/**
 * Calendar Stimulus Controller
 * 
 * Manages calendar date selection with month/year navigation
 * Supports keyboard navigation (arrow keys for dates, month/year selection)
 * 
 * Usage:
 *   <div data-controller="ui--calendar" data-ui--calendar-month-value="0" data-ui--calendar-year-value="2024">
 *     <div data-ui--calendar-target="header">
 *       <button data-action="click->ui--calendar#previousMonth">Previous</button>
 *       <span data-ui--calendar-target="monthYear">January 2024</span>
 *       <button data-action="click->ui--calendar#nextMonth">Next</button>
 *     </div>
 *     <div data-ui--calendar-target="weekdays">
 *       <div>Sun</div>
 *       <div>Mon</div>
 *       ...
 *     </div>
 *     <div data-ui--calendar-target="days">
 *       <button data-date="2024-01-01" data-action="click->ui--calendar#selectDate">1</button>
 *       ...
 *     </div>
 *   </div>
 * 
 * Values:
 *   - month (Number): Current month (0-11, default: current month)
 *   - year (Number): Current year (default: current year)
 *   - selectedDate (String): Selected date in ISO format (YYYY-MM-DD)
 * 
 * Actions:
 *   - previousMonth: Go to previous month
 *   - nextMonth: Go to next month
 *   - selectDate: Select a date
 *   - keydown: Handle keyboard navigation
 * 
 * Events dispatched:
 *   - ui:calendar:selected - { date: string }
 *   - ui:calendar:monthChanged - { month: number, year: number }
 */
export default class extends BaseController {
  static values = {
    month: { type: Number, default: new Date().getMonth() },
    year: { type: Number, default: new Date().getFullYear() },
    selectedDate: String,
    selectedDates: Array,
    rangeStart: String,
    rangeEnd: String,
    minDate: String,
    maxDate: String,
    disabledDates: Array
  }

  static targets = ["header", "monthYear", "weekdays", "days", "dayButton"]

  connect() {
    this.element.setAttribute('role', 'application')
    this.element.setAttribute('aria-label', 'Calendar')
    
    // Render calendar
    this.renderCalendar()
  }

  /**
   * Go to previous month
   * @param {Event} event - Click event
   */
  previousMonth(event) {
    event.preventDefault()
    
    if (this.monthValue === 0) {
      this.monthValue = 11
      this.yearValue -= 1
    } else {
      this.monthValue -= 1
    }
  }

  /**
   * Go to next month
   * @param {Event} event - Click event
   */
  nextMonth(event) {
    event.preventDefault()
    
    if (this.monthValue === 11) {
      this.monthValue = 0
      this.yearValue += 1
    } else {
      this.monthValue += 1
    }
  }

  /**
   * Select a date
   * @param {Event} event - Click event
   */
  selectDate(event) {
    event.preventDefault()
    if (event.currentTarget.disabled) return

    const date = event.currentTarget.getAttribute('data-date')
    if (date) {
      const mode = this.calendarMode()

      if (mode === 'multiple') {
        const selected = this.getSelectedDates()
        const index = selected.indexOf(date)

        if (index >= 0) {
          selected.splice(index, 1)
        } else {
          selected.push(date)
          selected.sort()
        }

        this.selectedDatesValue = selected
        this.dispatchStateChange('ui:calendar:selected', { dates: selected })
      } else if (mode === 'range') {
        this.updateRangeSelection(date)
        this.dispatchStateChange('ui:calendar:selected', {
          start: this.rangeStartValue || null,
          end: this.rangeEndValue || null
        })
      } else {
        this.selectedDateValue = date
        this.dispatchStateChange('ui:calendar:selected', { date })
      }

      this.renderCalendar()
    }
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  keydown(event) {
    const buttons = Array.from(this.dayButtonTargets)
    const selectedButton =
      this.element.querySelector('[data-date][aria-selected="true"]') ||
      this.element.querySelector('[data-date].selected')
    
    if (!selectedButton) return

    const currentIndex = buttons.indexOf(selectedButton)
    let nextIndex = currentIndex

    switch (event.key) {
      case 'ArrowRight':
        event.preventDefault()
        nextIndex = Math.min(currentIndex + 1, buttons.length - 1)
        break
      case 'ArrowLeft':
        event.preventDefault()
        nextIndex = Math.max(currentIndex - 1, 0)
        break
      case 'ArrowDown':
        event.preventDefault()
        nextIndex = Math.min(currentIndex + 7, buttons.length - 1)
        break
      case 'ArrowUp':
        event.preventDefault()
        nextIndex = Math.max(currentIndex - 7, 0)
        break
      default:
        return
    }

    const nextButton = buttons[nextIndex]
    if (nextButton) {
      nextButton.focus()
    }
  }

  /**
   * Update calendar when month/year changes
   */
  monthValueChanged() {
    this.renderCalendar()
    this.dispatchStateChange('ui:calendar:monthChanged', {
      month: this.monthValue,
      year: this.yearValue
    })
  }

  yearValueChanged() {
    this.renderCalendar()
    this.dispatchStateChange('ui:calendar:monthChanged', {
      month: this.monthValue,
      year: this.yearValue
    })
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

    // Update month/year display
    if (this.hasMonthYearTarget) {
      this.monthYearTarget.textContent = `${monthNames[this.monthValue]} ${this.yearValue}`
    }

    // Get first day of month and number of days
    const firstDay = new Date(this.yearValue, this.monthValue, 1).getDay()
    const daysInMonth = new Date(this.yearValue, this.monthValue + 1, 0).getDate()
    const daysInPrevMonth = new Date(this.yearValue, this.monthValue, 0).getDate()

    // Clear existing days
    this.daysTarget.innerHTML = ''

    const todayStr = this.formatDate(new Date())
    const mode = this.calendarMode()
    const selectedDates = mode === 'multiple' ? this.getSelectedDates() : []
    const rangeStart = mode === 'range' ? this.rangeStartValue : null
    const rangeEnd = mode === 'range' ? this.rangeEndValue : null
    let cellIndex = 0
    let row = this.createRow()

    const appendCell = (button) => {
      const cell = this.createCell()
      cell.appendChild(button)
      row.appendChild(cell)
      cellIndex += 1

      if (cellIndex % 7 === 0) {
        this.daysTarget.appendChild(row)
        row = this.createRow()
      }
    }

    // Add previous month's trailing days
    for (let i = firstDay - 1; i >= 0; i--) {
      const day = daysInPrevMonth - i
      const button = this.createDayButton(day, this.monthValue - 1, this.yearValue, true, null)
      appendCell(button)
    }

    // Add current month's days
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(this.yearValue, this.monthValue, day)
      const dateStr = this.formatDate(date)
      const button = this.createDayButton(day, this.monthValue, this.yearValue, false, dateStr)

      const isDisabled = this.isDateDisabled(dateStr, false)
      const isSelectedSingle = mode === 'single' && this.hasSelectedDateValue && this.selectedDateValue === dateStr
      const isSelectedMultiple = mode === 'multiple' && selectedDates.includes(dateStr)
      const isRangeStart = mode === 'range' && rangeStart && dateStr === rangeStart
      const isRangeEnd = mode === 'range' && rangeEnd && dateStr === rangeEnd
      const isInRange = mode === 'range' && rangeStart && rangeEnd && dateStr >= rangeStart && dateStr <= rangeEnd
      const isRangeMiddle = isInRange && !isRangeStart && !isRangeEnd
      const isRangeSingle = isRangeStart && isRangeEnd
      const isSelected =
        isSelectedSingle ||
        isSelectedMultiple ||
        isInRange ||
        isRangeStart ||
        isRangeEnd ||
        isRangeSingle

      if (dateStr === todayStr && !isSelected) {
        button.classList.add('bg-accent', 'text-accent-foreground')
      }

      if (isSelected) {
        button.setAttribute('aria-selected', 'true')
        button.setAttribute('data-state', 'selected')
      }

      if (isSelectedSingle || isSelectedMultiple || isRangeSingle || isRangeStart || isRangeEnd) {
        button.classList.add(
          'bg-primary',
          'text-primary-foreground',
          'hover:bg-primary',
          'hover:text-primary-foreground',
          'focus:bg-primary',
          'focus:text-primary-foreground'
        )
      }

      if (isRangeMiddle) {
        button.classList.add(
          'bg-accent',
          'text-accent-foreground',
          'hover:bg-accent',
          'hover:text-accent-foreground',
          'rounded-none'
        )
      }

      if (isRangeStart && !isRangeSingle) {
        button.classList.add('rounded-l-md')
      }

      if (isRangeEnd && !isRangeSingle) {
        button.classList.add('rounded-r-md')
      }

      if (!isDisabled) {
        button.addEventListener('click', (e) => this.selectDate(e))
      }
      appendCell(button)
    }

    // Add next month's leading days
    const remainingCells = 42 - cellIndex // 6 weeks * 7 days
    for (let day = 1; day <= remainingCells; day++) {
      const button = this.createDayButton(day, this.monthValue + 1, this.yearValue, true, null)
      appendCell(button)
    }
  }

  /**
   * Create a day button element
   * @param {number} day - Day number
   * @param {number} month - Month (0-11)
   * @param {number} year - Year
   * @param {boolean} isOtherMonth - Whether it's from another month
   * @returns {HTMLElement} Button element
   */
  createDayButton(day, month, year, isOtherMonth, dateStr) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = [
      'inline-flex',
      'h-9',
      'w-9',
      'items-center',
      'justify-center',
      'rounded-md',
      'p-0',
      'text-sm',
      'font-normal',
      'transition-colors',
      'hover:bg-accent',
      'hover:text-accent-foreground',
      'focus-visible:outline-none',
      'focus-visible:ring-2',
      'focus-visible:ring-ring',
      'focus-visible:ring-offset-2',
      'disabled:pointer-events-none',
      'disabled:opacity-50'
    ].join(' ')
    button.textContent = day
    button.setAttribute('aria-label', `${day}`)
    button.setAttribute('data-ui--calendar-target', 'dayButton')

    if (dateStr) {
      button.setAttribute('data-date', dateStr)
    }

    const isDisabled = this.isDateDisabled(dateStr, isOtherMonth)

    if (isDisabled || isOtherMonth) {
      button.setAttribute('data-state', 'disabled')
      button.disabled = true
      button.classList.add('text-muted-foreground', 'opacity-50')
      if (isOtherMonth) {
        button.classList.add('day-outside')
      }
    } else {
      button.setAttribute('data-state', 'enabled')
    }
    
    return button
  }

  createRow() {
    return document.createElement('tr')
  }

  createCell() {
    const cell = document.createElement('td')
    cell.setAttribute('role', 'gridcell')
    cell.className = 'relative p-0 text-center text-sm focus-within:relative focus-within:z-20'
    return cell
  }

  calendarMode() {
    const mode = this.element.dataset.mode
    return mode || 'single'
  }

  getSelectedDates() {
    if (this.hasSelectedDatesValue) {
      return [...this.selectedDatesValue]
    }

    const raw = this.element.dataset.selectedDates
    return this.normalizeDateList(raw)
  }

  updateRangeSelection(date) {
    if (!this.rangeStartValue || this.rangeEndValue) {
      this.rangeStartValue = date
      this.rangeEndValue = ''
      return
    }

    if (date < this.rangeStartValue) {
      this.rangeEndValue = this.rangeStartValue
      this.rangeStartValue = date
      return
    }

    this.rangeEndValue = date
  }

  isDateDisabled(dateStr, isOtherMonth) {
    if (isOtherMonth || !dateStr) return true

    const minDate = this.getMinDate()
    const maxDate = this.getMaxDate()
    const disabledDates = this.getDisabledDates()

    if (minDate && dateStr < minDate) return true
    if (maxDate && dateStr > maxDate) return true

    return disabledDates.includes(dateStr)
  }

  getMinDate() {
    if (this.hasMinDateValue) return this.minDateValue
    return this.element.dataset.minDate || null
  }

  getMaxDate() {
    if (this.hasMaxDateValue) return this.maxDateValue
    return this.element.dataset.maxDate || null
  }

  getDisabledDates() {
    if (this.hasDisabledDatesValue) {
      return this.normalizeDateList(this.disabledDatesValue)
    }

    return this.normalizeDateList(this.element.dataset.disabledDates)
  }

  normalizeDateList(value) {
    if (!value) return []

    if (Array.isArray(value)) {
      return value.map((date) => date.toString())
    }

    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value)
        if (Array.isArray(parsed)) {
          return parsed.map((date) => date.toString())
        }
      } catch (error) {
        return value
          .split(',')
          .map((date) => date.trim())
          .filter((date) => date.length > 0)
      }
    }

    return []
  }

  /**
   * Format date as ISO string (YYYY-MM-DD)
   * @param {Date} date - Date object
   * @returns {string} Formatted date
   */
  formatDate(date) {
    const year = date.getFullYear()
    const month = `${date.getMonth() + 1}`.padStart(2, '0')
    const day = `${date.getDate()}`.padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}
