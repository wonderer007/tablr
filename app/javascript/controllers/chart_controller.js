import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "form", "startDate", "endDate", "chartTitle", "chartDescription",
    "dataType", "ratingFilters", "reviewFilters", "sentimentFilters", "suggestionsFilters",
    "starToggle", "foodToggle", "serviceToggle", "atmosphereToggle",
    "totalReviewsToggle", "positiveToggle", "negativeToggle", "neutralToggle",
    "totalKeywordsToggle", "positiveKeywordsToggle", "negativeKeywordsToggle", "neutralKeywordsToggle", "categorySelect",
    "suggestionsToggle", "complainsToggle"
  ]

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

    // Data type dropdown
    this.dataTypeTarget.addEventListener('change', () => {
      this.toggleFilterCategories()
      this.updateChartLabels()
      this.fetchAndRenderChart()
    })

    // Rating toggles
    if (this.hasStarToggleTarget) {
      [this.starToggleTarget, this.foodToggleTarget, this.serviceToggleTarget, this.atmosphereToggleTarget].forEach(toggle => {
        toggle.addEventListener('change', () => {
          if (this.chartData) this.renderChart(this.chartData)
        })
      })
    }

    // Review toggles
    if (this.hasTotalReviewsToggleTarget) {
      [this.totalReviewsToggleTarget, this.positiveToggleTarget, this.negativeToggleTarget, this.neutralToggleTarget].forEach(toggle => {
        toggle.addEventListener('change', () => {
          if (this.chartData) this.renderChart(this.chartData)
        })
      })
    }

    // Sentiment analysis toggles and category selection
    if (this.hasTotalKeywordsToggleTarget) {
      [this.totalKeywordsToggleTarget, this.positiveKeywordsToggleTarget, this.negativeKeywordsToggleTarget, this.neutralKeywordsToggleTarget].forEach(toggle => {
        toggle.addEventListener('change', () => {
          if (this.chartData) this.renderChart(this.chartData)
        })
      })
    }

    // Category selection dropdown
    if (this.hasCategorySelectTarget) {
      this.categorySelectTarget.addEventListener('change', () => {
        this.updateChartLabels()
        this.fetchAndRenderChart()
      })
    }

    // Suggestions & Complains toggles
    if (this.hasSuggestionsToggleTarget) {
      [this.suggestionsToggleTarget, this.complainsToggleTarget].forEach(toggle => {
        toggle.addEventListener('change', () => {
          if (this.chartData) this.renderChart(this.chartData)
        })
      })
    }
  }

  toggleFilterCategories() {
    const selectedDataType = this.getSelectedDataType()
    
    // Hide all filter sections first
    this.ratingFiltersTarget.classList.add('hidden')
    this.reviewFiltersTarget.classList.add('hidden')
    this.sentimentFiltersTarget.classList.add('hidden')
    this.suggestionsFiltersTarget.classList.add('hidden')
    
    // Show the relevant filter section
    if (selectedDataType === 'ratings') {
      this.ratingFiltersTarget.classList.remove('hidden')
    } else if (selectedDataType === 'reviews') {
      this.reviewFiltersTarget.classList.remove('hidden')
    } else if (selectedDataType === 'sentiment_analysis') {
      this.sentimentFiltersTarget.classList.remove('hidden')
    } else if (selectedDataType === 'suggestions_complains') {
      this.suggestionsFiltersTarget.classList.remove('hidden')
    }
  }

  updateChartLabels() {
    const selectedDataType = this.getSelectedDataType()
    
    if (selectedDataType === 'ratings') {
      this.chartTitleTarget.textContent = 'Rating Comparison Chart'
      this.chartDescriptionTarget.textContent = 'Visual comparison of average ratings over time by category.'
    } else if (selectedDataType === 'reviews') {
      this.chartTitleTarget.textContent = 'Reviews Analysis Chart'
      this.chartDescriptionTarget.textContent = 'Visual comparison of review counts over time by sentiment.'
    } else if (selectedDataType === 'sentiment_analysis') {
      const selectedCategoryId = this.getSelectedCategory()
      const categoryName = selectedCategoryId ? 
        this.categorySelectTarget.options[this.categorySelectTarget.selectedIndex].text : 
        'All Categories'
      
      this.chartTitleTarget.textContent = `Sentiment Analysis: ${categoryName}`
      this.chartDescriptionTarget.textContent = `Keyword sentiment analysis for ${categoryName.toLowerCase()} over time.`
    } else {
      this.chartTitleTarget.textContent = 'Suggestions & Complains Chart'
      this.chartDescriptionTarget.textContent = 'Visual comparison of suggestions and complains count over time.'
    }
  }

  getSelectedDataType() {
    return this.dataTypeTarget.value || 'ratings'
  }

  getSelectedCategory() {
    return this.hasCategorySelectTarget ? this.categorySelectTarget.value : ''
  }

  fetchAndRenderChart() {
    const startDate = this.startDateTarget.value
    const endDate = this.endDateTarget.value
    const dataType = this.getSelectedDataType()
    const categoryId = this.getSelectedCategory()

    let url = `/comparisons.json?start_date=${startDate}&end_date=${endDate}&data_type=${dataType}`
    if (dataType === 'sentiment_analysis' && categoryId) {
      url += `&category_id=${categoryId}`
    }

    fetch(url)
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
    const selectedDataType = this.getSelectedDataType()
    
    if (selectedDataType === 'ratings') {
      this.renderRatingsChart(data)
    } else if (selectedDataType === 'reviews') {
      this.renderReviewsChart(data)
    } else if (selectedDataType === 'sentiment_analysis') {
      this.renderSentimentAnalysisChart(data)
    } else {
      this.renderSuggestionsChart(data)
    }
  }

  renderRatingsChart(data) {
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

  renderReviewsChart(data) {
    const labels = data.map(item => item.month)
    const datasets = []

    // Add total reviews dataset
    if (this.totalReviewsToggleTarget.checked && data.length > 0 && data[0].total_reviews !== undefined) {
      datasets.push({
        label: 'Total Reviews',
        data: data.map(item => item.total_reviews),
        backgroundColor: 'rgba(99, 102, 241, 0.7)',
      })
    }

    // Add positive reviews dataset
    if (this.positiveToggleTarget.checked && data.length > 0 && data[0].positive_reviews !== undefined) {
      datasets.push({
        label: 'Positive',
        data: data.map(item => item.positive_reviews),
        backgroundColor: 'rgba(16, 185, 129, 0.7)',
      })
    }

    // Add negative reviews dataset
    if (this.negativeToggleTarget.checked && data.length > 0 && data[0].negative_reviews !== undefined) {
      datasets.push({
        label: 'Negative',
        data: data.map(item => item.negative_reviews),
        backgroundColor: 'rgba(239, 68, 68, 0.7)',
      })
    }

    // Add neutral reviews dataset
    if (this.neutralToggleTarget.checked && data.length > 0 && data[0].neutral_reviews !== undefined) {
      datasets.push({
        label: 'Neutral',
        data: data.map(item => item.neutral_reviews),
        backgroundColor: 'rgba(156, 163, 175, 0.7)',
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
            beginAtZero: true
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

  renderSentimentAnalysisChart(data) {
    const labels = data.map(item => item.month)
    const datasets = []

    // Add keyword sentiment datasets based on selected toggles
    if (this.totalKeywordsToggleTarget.checked && data.length > 0 && data[0].total_keywords !== undefined) {
      datasets.push({
        label: 'Total Keywords',
        data: data.map(item => item.total_keywords),
        backgroundColor: 'rgba(99, 102, 241, 0.7)',
      })
    }

    if (this.positiveKeywordsToggleTarget.checked && data.length > 0 && data[0].positive_keywords !== undefined) {
      datasets.push({
        label: 'Positive Keywords',
        data: data.map(item => item.positive_keywords),
        backgroundColor: 'rgba(16, 185, 129, 0.7)',
      })
    }

    if (this.negativeKeywordsToggleTarget.checked && data.length > 0 && data[0].negative_keywords !== undefined) {
      datasets.push({
        label: 'Negative Keywords',
        data: data.map(item => item.negative_keywords),
        backgroundColor: 'rgba(239, 68, 68, 0.7)',
      })
    }

    if (this.neutralKeywordsToggleTarget.checked && data.length > 0 && data[0].neutral_keywords !== undefined) {
      datasets.push({
        label: 'Neutral Keywords',
        data: data.map(item => item.neutral_keywords),
        backgroundColor: 'rgba(156, 163, 175, 0.7)',
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
            beginAtZero: true
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

  renderSuggestionsChart(data) {
    const labels = data.map(item => item.month)
    const datasets = []

    // Add suggestions dataset
    if (this.suggestionsToggleTarget.checked && data.length > 0 && data[0].suggestions_count !== undefined) {
      datasets.push({
        label: 'Suggestions',
        data: data.map(item => item.suggestions_count),
        backgroundColor: 'rgba(16, 185, 129, 0.7)',
      })
    }

    // Add complains dataset
    if (this.complainsToggleTarget.checked && data.length > 0 && data[0].complains_count !== undefined) {
      datasets.push({
        label: 'Complains',
        data: data.map(item => item.complains_count),
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
            beginAtZero: true
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