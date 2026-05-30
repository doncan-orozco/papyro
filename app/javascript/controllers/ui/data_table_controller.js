import BaseController from "controllers/ui/base_controller"

/**
 * Data Table Stimulus Controller
 * 
 * Manages data table operations: sorting, filtering, pagination
 * Supports keyboard navigation and accessibility
 * 
 * Usage:
 *   <div data-controller="ui--data-table" 
 *        data-ui--data-table-sort-by-value="name"
 *        data-ui--data-table-sort-order-value="asc">
 *     <table>
 *       <thead>
 *         <tr>
 *           <th data-ui--data-table-target="sortable" 
 *               data-column="name"
 *               data-action="click->ui--data-table#sort">
 *             Name
 *           </th>
 *         </tr>
 *       </thead>
 *       <tbody data-ui--data-table-target="body">
 *         <tr data-ui--data-table-target="row">...</tr>
 *       </tbody>
 *     </table>
 *   </div>
 * 
 * Values:
 *   - sortBy (String): Column to sort by
 *   - sortOrder (String): "asc" or "desc"
 *   - currentPage (Number): Current page (default: 1)
 *   - pageSize (Number): Rows per page (default: 10)
 * 
 * Actions:
 *   - sort: Sort by column
 *   - filterRows: Filter rows by criteria
 *   - goToPage: Go to specific page
 *
 * Events dispatched:
 *   - ui:data-table:sorted - { column: string, order: string }
 *   - ui:data-table:paginated - { page: number, pageSize: number }
 */
export default class extends BaseController {
  static values = {
    sortBy: String,
    sortOrder: { type: String, default: "asc" },
    currentPage: { type: Number, default: 1 },
    pageSize: { type: Number, default: 10 }
  }

  static targets = ["sortable", "body", "row"]

  connect() {
    this.allRows = Array.from(this.rowTargets)
  }

  /**
   * Sort by column
   * @param {Event} event - Click event
   */
  sort(event) {
    event.preventDefault()
    
    const column = event.currentTarget.getAttribute('data-column')
    if (!column) return


    // Toggle sort order if same column
    if (this.sortByValue === column) {
      this.sortOrderValue = this.sortOrderValue === 'asc' ? 'desc' : 'asc'
    } else {
      this.sortByValue = column
      this.sortOrderValue = 'asc'
    }

    this.updateSortIndicators()
    this.sortRows()
    this.currentPageValue = 1

    this.dispatchStateChange('ui:data-table:sorted', {
      column: this.sortByValue,
      order: this.sortOrderValue
    })
  }

  /**
   * Filter rows by criteria
   * @param {string} query - Filter query
   */
  filterRows(query) {
    if (!query) {
      // Show all rows
      this.allRows = Array.from(this.rowTargets)
    } else {
      // Filter rows
      const lowerQuery = query.toLowerCase()
      this.allRows = Array.from(this.rowTargets).filter(row => {
        return row.textContent.toLowerCase().includes(lowerQuery)
      })
    }

    this.currentPageValue = 1
    this.renderTable()
  }

  /**
   * Go to specific page
   * @param {number} page - Page number
   */
  goToPage(page) {
    if (page < 1) return
    
    const maxPage = Math.ceil(this.allRows.length / this.pageSizeValue)
    if (page > maxPage) return
    
    this.currentPageValue = page
    this.renderTable()

    this.dispatchStateChange('ui:data-table:paginated', {
      page: this.currentPageValue,
      pageSize: this.pageSizeValue
    })
  }

  /**
   * Sort rows array
   */
  sortRows() {
    if (!this.hasSortByValue) return

    this.allRows.sort((a, b) => {
      let aVal = a.getAttribute(`data-${this.sortByValue}`) || a.textContent
      let bVal = b.getAttribute(`data-${this.sortByValue}`) || b.textContent

      // Try numeric comparison
      const aNum = parseFloat(aVal)
      const bNum = parseFloat(bVal)

      if (!isNaN(aNum) && !isNaN(bNum)) {
        return this.sortOrderValue === 'asc' ? aNum - bNum : bNum - aNum
      }

      // String comparison
      aVal = String(aVal).toLowerCase()
      bVal = String(bVal).toLowerCase()

      if (this.sortOrderValue === 'asc') {
        return aVal.localeCompare(bVal)
      } else {
        return bVal.localeCompare(aVal)
      }
    })
  }

  /**
   * Render table with current sorting and pagination
   */
  renderTable() {
    if (!this.hasBodyTarget) return

    // Calculate pagination
    const start = (this.currentPageValue - 1) * this.pageSizeValue
    const end = start + this.pageSizeValue
    const pageRows = this.allRows.slice(start, end)

    // Update body
    this.bodyTarget.innerHTML = ''
    pageRows.forEach(row => {
      this.bodyTarget.appendChild(row.cloneNode(true))
    })
  }

  /**
   * Update sort indicators on headers
   */
  updateSortIndicators() {
    this.sortableTargets.forEach(header => {
      const column = header.getAttribute('data-column')
      const isActive = column === this.sortByValue

      if (isActive) {
        header.setAttribute('data-sort', this.sortOrderValue)
        header.setAttribute('aria-sort', this.sortOrderValue === 'asc' ? 'ascending' : 'descending')
      } else {
        header.removeAttribute('data-sort')
        header.setAttribute('aria-sort', 'none')
      }
    })
  }
}
