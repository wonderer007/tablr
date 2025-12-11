class ReviewAnalyticsService
  def initialize(place:, start_date:, end_date:)
    @place = place
    @start_date = start_date
    @end_date = end_date
  end

  def call
    ActsAsTenant.with_tenant(place) do
      {
        total_reviews: reviews.count,
        average_rating: average_rating,
        sentiment_stats: sentiment_stats,
        rating_stats: rating_stats,
        complaints_data: complaints_data,
        suggestions_data: suggestions_data,
        keywords_by_category: keywords_by_category,
        previous_period_comparison: previous_period_comparison
      }
    end
  end

  private

  attr_reader :place, :start_date, :end_date

  def reviews
    @reviews ||= Review.includes(:keywords, :complains, :suggestions, :place)
                       .where(published_at: start_date..end_date, processed: true)
  end

  def review_ids
    @review_ids ||= reviews.pluck(:id)
  end

  def average_rating
    reviews.average(:stars)&.round(1) || 0
  end

  def sentiment_stats
    compute_sentiment_stats(reviews)
  end

  def compute_sentiment_stats(scope)
    total = scope.count

    return default_sentiment_stats if total.zero?

    positive_count = scope.where(sentiment: :positive).count
    negative_count = scope.where(sentiment: :negative).count
    neutral_count = scope.where(sentiment: :neutral).count

    {
      positive: positive_count,
      negative: negative_count,
      neutral: neutral_count,
      total: total,
      positive_percentage: percentage(positive_count, total),
      negative_percentage: percentage(negative_count, total),
      neutral_percentage: percentage(neutral_count, total)
    }
  end

  def default_sentiment_stats
    {
      positive: 0,
      negative: 0,
      neutral: 0,
      total: 0,
      positive_percentage: 0.0,
      negative_percentage: 0.0,
      neutral_percentage: 0.0
    }
  end

  def percentage(value, total)
    return 0.0 if total.zero?

    ((value.to_f / total) * 100).round(1)
  end

  def rating_stats
    {
      food_rating: average_for_column(:food_rating),
      service_rating: average_for_column(:service_rating),
      atmosphere_rating: average_for_column(:atmosphere_rating),
      star_distribution: star_distribution
    }
  end

  def average_for_column(column)
    reviews.where.not(column => nil).average(column)&.round(1) || 0
  end

  def star_distribution
    (1..5).map do |star|
      {
        stars: star,
        count: reviews.where(stars: star).count
      }
    end
  end

  def complaints_data
    return empty_complaints_data if review_ids.empty?

    complaints = Complain.joins(:review)
                         .where(reviews: { id: review_ids })
                         .includes(:category)

    top_complaints = complaints.group(:text)
                               .order(Arel.sql('count_all DESC'))
                               .limit(3)
                               .count

    complaints_by_category = complaints.joins(:category)
                                       .group('categories.name')
                                       .count

    {
      total_count: complaints.count,
      top_complaints: top_complaints.map { |text, count| { text: text, count: count } },
      by_category: complaints_by_category
    }
  end

  def suggestions_data
    return empty_suggestions_data if review_ids.empty?

    suggestions = Suggestion.joins(:review)
                            .where(reviews: { id: review_ids })
                            .includes(:category)

    top_suggestions = suggestions.group(:text)
                                 .order(Arel.sql('count_all DESC'))
                                 .limit(3)
                                 .count

    suggestions_by_category = suggestions.joins(:category)
                                         .group('categories.name')
                                         .count

    {
      total_count: suggestions.count,
      top_suggestions: top_suggestions.map { |text, count| { text: text, count: count } },
      by_category: suggestions_by_category
    }
  end

  def empty_complaints_data
    {
      total_count: 0,
      top_complaints: [],
      by_category: {}
    }
  end

  def empty_suggestions_data
    {
      total_count: 0,
      top_suggestions: [],
      by_category: {}
    }
  end

  def keywords_by_category
    return [] if review_ids.empty?

    keywords_relation = Keyword.joins(:review)
                               .where(reviews: { id: review_ids })
                               .includes(:category)

    Category.includes(:keywords).map do |category|
      category_keywords = keywords_relation.where(category: category)

      top_positive = category_keywords.where(sentiment: :positive)
                                      .group(:name)
                                      .order(Arel.sql('count_all DESC'))
                                      .limit(3)
                                      .count

      top_negative = category_keywords.where(sentiment: :negative)
                                      .group(:name)
                                      .order(Arel.sql('count_all DESC'))
                                      .limit(3)
                                      .count

      total_keywords = category_keywords.count

      next if total_keywords.zero?

      {
        name: category.name,
        total_keywords: total_keywords,
        top_positive: top_positive.map { |name, count| { name: name, count: count } },
        top_negative: top_negative.map { |name, count| { name: name, count: count } }
      }
    end.compact
       .sort_by { |cat| cat[:total_keywords] }
       .reverse
       .take(3)
  end

  def previous_period_comparison
    period_duration = (end_date - start_date).to_i

    previous_start = start_date - period_duration - 1
    previous_end = start_date - 1

    previous_reviews = Review.where(published_at: previous_start..previous_end, processed: true)

    current_average = reviews.average(:stars) || 0
    previous_average = previous_reviews.average(:stars) || 0

    current_sentiment = sentiment_stats
    previous_sentiment = compute_sentiment_stats(previous_reviews)

    {
      rating_change: (current_average - previous_average).round(2),
      review_count_change: reviews.count - previous_reviews.count,
      sentiment_change: {
        positive: (current_sentiment[:positive_percentage] - previous_sentiment[:positive_percentage]).round(1),
        negative: (current_sentiment[:negative_percentage] - previous_sentiment[:negative_percentage]).round(1)
      }
    }
  end
end

