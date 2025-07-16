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
      onClear: () => {
        this.startDateTarget.value = ""
        this.endDateTarget.value = ""
        this.inputTarget.value = ""
      }
    }

    // Set initial values if they exist
    if (this.startDateValue && this.endDateValue) {
      options.defaultDate = [this.startDateValue, this.endDateValue]
    } else if (this.startDateValue) {
      options.defaultDate = [this.startDateValue]
    }

    this.flatpickr = flatpickr(this.inputTarget, options)
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