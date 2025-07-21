import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
// import "flatpickr/dist/flatpickr.css"

export default class extends Controller {
  static targets = ["input", "startDate", "endDate"]
  static values = { 
    startDate: String,
    endDate: String
  }

  connect() {
    this.initializeDateRangePicker()
  }

  disconnect() {
    if (this.flatpickr) {
      this.flatpickr.destroy()
    }
  }

  initializeDateRangePicker() {
    // Get initial values from hidden inputs or from Stimulus values
    const startDate = this.startDateTarget.value || this.startDateValue
    const endDate = this.endDateTarget.value || this.endDateValue

    const options = {
      mode: "range",
      dateFormat: "Y-m-d",
      allowInput: false, // Prevent manual input to avoid parsing issues
      clickOpens: true,
      onChange: (selectedDates, dateStr) => {
        if (selectedDates.length === 2) {
          const [startDate, endDate] = selectedDates
          this.startDateTarget.value = this.formatDate(startDate)
          this.endDateTarget.value = this.formatDate(endDate)
          this.inputTarget.value = dateStr // Use flatpickr's formatted string
        } else if (selectedDates.length === 1) {
          const [startDate] = selectedDates
          this.startDateTarget.value = this.formatDate(startDate)
          this.endDateTarget.value = ""
          this.inputTarget.value = dateStr // Use flatpickr's formatted string
        } else {
          this.startDateTarget.value = ""
          this.endDateTarget.value = ""
          this.inputTarget.value = ""
        }
      },
      onClose: (selectedDates, dateStr) => {
        // Update the input value with flatpickr's formatted string on close
        this.inputTarget.value = dateStr
      },
      onReady: (selectedDates, dateStr) => {
        // Ensure the input shows the selected range when flatpickr is ready
        if (selectedDates.length > 0) {
          this.inputTarget.value = dateStr
        } else {
          // Set initial display value if no dates were auto-selected
          this.setInitialDisplayValue(startDate, endDate)
        }
      },
      onClear: () => {
        this.startDateTarget.value = ""
        this.endDateTarget.value = ""
        this.inputTarget.value = ""
      }
    }

    // Set initial values if they exist
    if (startDate && endDate) {
      options.defaultDate = [startDate, endDate]
    } else if (startDate) {
      options.defaultDate = [startDate]
    }

    this.flatpickr = flatpickr(this.inputTarget, options)
  }

  setInitialDisplayValue(startDate, endDate) {
    if (startDate && endDate) {
      // Format the date range for display (matches flatpickr's format)
      const formattedStart = this.formatDisplayDate(startDate)
      const formattedEnd = this.formatDisplayDate(endDate)
      this.inputTarget.value = `${formattedStart} to ${formattedEnd}`
    } else if (startDate) {
      this.inputTarget.value = this.formatDisplayDate(startDate)
    }
  }

  formatDisplayDate(dateString) {
    // Convert YYYY-MM-DD to a more readable format or keep as is for consistency
    return dateString
  }

  formatDate(date) {
    // Use local date to avoid timezone issues
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  }

  clear() {
    if (this.flatpickr) {
      this.flatpickr.clear()
    }
    this.startDateTarget.value = ""
    this.endDateTarget.value = ""
    this.inputTarget.value = ""
    
    // Submit the form to refresh with default values
    const form = this.element.closest('form')
    if (form) {
      form.submit()
    }
  }
} 