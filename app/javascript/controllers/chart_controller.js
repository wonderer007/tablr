import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "form", "starToggle", "foodToggle", "serviceToggle", "atmosphereToggle", "startDate", "endDate"]

  connect() {
    // Dynamically load Chart.js if not already loaded
    if (typeof Chart === 'undefined') {
      this.loadChartJS().then(() => {
        this.initializeChart()
      })
    } else {
      this.initializeChart()
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  async loadChartJS() {
    return new Promise((resolve) => {
      if (document.querySelector('script[src*="chart.js"]')) {
        resolve()
        return
      }
      
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js'
      script.onload = resolve
      document.head.appendChild(script)
    })
  }

  initializeChart() {
    const ctx = this.canvasTarget.getContext('2d')
    this.chartData = null

    // Initial render
    this.fetchAndRenderChart()

    // Setup event listeners
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Form submission
    this.formTarget.addEventListener('submit', (e) => {
      e.preventDefault()
      this.fetchAndRenderChart()
    })

    // Toggle checkboxes
    [this.starToggleTarget, this.foodToggleTarget, this.serviceToggleTarget, this.atmosphereToggleTarget].forEach(toggle => {
      toggle.addEventListener('change', () => {
        if (this.chartData) this.renderChart(this.chartData)
      })
    })
  }

  fetchAndRenderChart() {
    const startDate = this.startDateTarget.value
    const endDate = this.endDateTarget.value

    fetch(`/comparisons.json?start_date=${startDate}&end_date=${endDate}`)
      .then(response => response.json())
      .then(data => {
        this.chartData = data
        this.renderChart(this.chartData)
      })
      .catch(error => {
        console.error('Error fetching chart data:', error)
      })
  }

  renderChart(data) {
    const labels = data.map(item => item.month)
    const starRatings = data.map(item => item.average_rating)
    const foodRatings = data.map(item => item.food_rating)
    const serviceRatings = data.map(item => item.service_rating)
    const atmosphereRatings = data.map(item => item.atmosphere_rating)

    const datasets = []
    
    if (this.starToggleTarget.checked) {
      datasets.push({
        label: 'Star Rating',
        data: starRatings,
        backgroundColor: 'rgba(37, 99, 235, 0.7)',
      })
    }
    
    if (this.foodToggleTarget.checked) {
      datasets.push({
        label: 'Food Rating',
        data: foodRatings,
        backgroundColor: 'rgba(16, 185, 129, 0.7)',
      })
    }
    
    if (this.serviceToggleTarget.checked) {
      datasets.push({
        label: 'Service Rating',
        data: serviceRatings,
        backgroundColor: 'rgba(234, 179, 8, 0.7)',
      })
    }
    
    if (this.atmosphereToggleTarget.checked) {
      datasets.push({
        label: 'Atmosphere Rating',
        data: atmosphereRatings,
        backgroundColor: 'rgba(239, 68, 68, 0.7)',
      })
    }

    if (this.chart) this.chart.destroy()
    
    this.chart = new Chart(this.canvasTarget, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: datasets
      },
      options: {
        scales: {
          y: {
            beginAtZero: true,
            max: 5
          }
        },
        responsive: true,
        plugins: {
          legend: { position: 'top' },
          title: { display: false }
        }
      }
    })
  }
} 