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
      allowInput: true,
      clickOpens: true,
      onChange: (selectedDates, dateStr, instance) => {
        if (selectedDates.length === 2) {
          this.startDateTarget.value = this.formatDate(selectedDates[0])
          this.endDateTarget.value = this.formatDate(selectedDates[1])
        } else if (selectedDates.length === 1) {
          this.startDateTarget.value = this.formatDate(selectedDates[0])
          this.endDateTarget.value = ""
        } else {
          this.startDateTarget.value = ""
          this.endDateTarget.value = ""
        }
      },
      onClear: () => {
        this.startDateTarget.value = ""
        this.endDateTarget.value = ""
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
    return date.toISOString().split('T')[0]
  }

  clear() {
    if (this.flatpickr) {
      this.flatpickr.clear()
    }
    this.startDateTarget.value = ""
    this.endDateTarget.value = ""
  }
} 