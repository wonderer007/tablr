class RestaurantReportMailer < ApplicationMailer
  def periodic_report(user, place, start_date, end_date, report_type = 'weekly')
    @user = user
    @place = place
    @start_date = start_date
    @end_date = end_date
    @report_type = report_type
    
    # Set tenant context
    ActsAsTenant.with_tenant(place) do
      @report_data = generate_report_data
    end

    mail(
      to: user.email,
      subject: "#{@place.name} - #{@report_type.titleize} Performance Report (#{@start_date.strftime('%b %d %Y')} - #{@end_date.strftime('%b %d, %Y')})"
    )
  end

  private

  def generate_report_data
    reviews = Review.includes(:keywords, :complains, :suggestions, :place)
                   .where(published_at: @start_date..@end_date)
                   .where(processed: true)

    {
      # Review statistics
      total_reviews: reviews.count,
      average_rating: reviews.average(:stars)&.round(1) || 0,
      
      # Sentiment analysis
      sentiment_stats: calculate_sentiment_stats(reviews),
      
      # Rating breakdowns
      rating_stats: calculate_rating_stats(reviews),
      
      # Complaints and suggestions
      complaints_data: calculate_complaints_data(reviews),
      suggestions_data: calculate_suggestions_data(reviews),
      
      # Keywords by category
      keywords_by_category: calculate_keywords_by_category(reviews),

      # Review distribution by date
      daily_review_counts: get_daily_review_counts(reviews),
      
      # Comparison with previous period
      previous_period_comparison: get_previous_period_comparison(reviews)
    }
  end

  def calculate_sentiment_stats(reviews)
    total = reviews.count
    return { 
      positive: 0, 
      negative: 0, 
      neutral: 0, 
      total: 0,
      positive_percentage: 0.0,
      negative_percentage: 0.0,
      neutral_percentage: 0.0
    } if total.zero?

    positive_count = reviews.where(sentiment: :positive).count
    negative_count = reviews.where(sentiment: :negative).count
    neutral_count = reviews.where(sentiment: :neutral).count

    {
      positive: positive_count,
      negative: negative_count,
      neutral: neutral_count,
      total: total,
      positive_percentage: ((positive_count.to_f / total) * 100).round(1),
      negative_percentage: ((negative_count.to_f / total) * 100).round(1),
      neutral_percentage: ((neutral_count.to_f / total) * 100).round(1)
    }
  end

  def calculate_rating_stats(reviews)
    {
      food_rating: reviews.where.not(food_rating: nil).average(:food_rating)&.round(1) || 0,
      service_rating: reviews.where.not(service_rating: nil).average(:service_rating)&.round(1) || 0,
      atmosphere_rating: reviews.where.not(atmosphere_rating: nil).average(:atmosphere_rating)&.round(1) || 0,
      star_distribution: (1..5).map { |star| 
        { 
          stars: star, 
          count: reviews.where(stars: star).count 
        } 
      }
    }
  end

  def calculate_complaints_data(reviews)
    complaints = Complain.joins(:review)
                        .where(reviews: { id: reviews.pluck(:id) })
                        .includes(:category)

    top_complaints = complaints.group(:text)
                              .limit(3)
                              .order('count_all DESC')
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

  def calculate_suggestions_data(reviews)
    suggestions = Suggestion.joins(:review)
                           .where(reviews: { id: reviews.pluck(:id) })
                           .includes(:category)

    top_suggestions = suggestions.group(:text)
                                .limit(3)
                                .order('count_all DESC')
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

  def calculate_keywords_by_category(reviews)
    keywords = Keyword.joins(:review)
                     .where(reviews: { id: reviews.pluck(:id) })
                     .includes(:category)

    categories = Category.includes(:keywords)
    
    categories.map do |category|
      category_keywords = keywords.where(category: category)
      
      top_positive = category_keywords.where(sentiment: :positive)
                                    .group(:name)
                                    .limit(3)
                                    .order('count_all DESC')
                                    .count

      top_negative = category_keywords.where(sentiment: :negative)
                                    .group(:name)
                                    .limit(3)
                                    .order('count_all DESC')
                                    .count

      {
        name: category.name,
        total_keywords: category_keywords.count,
        top_positive: top_positive.map { |name, count| { name: name, count: count } },
        top_negative: top_negative.map { |name, count| { name: name, count: count } }
      }
    end.reject { |cat| cat[:total_keywords] == 0 }
       .sort_by { |cat| cat[:total_keywords] }
       .reverse.take(3)
  end

  def get_top_dishes(reviews)
    Keyword.joins(:review)
           .where(reviews: { id: reviews.pluck(:id) })
           .where(is_dish: true, sentiment: :positive)
           .group(:name)
           .limit(3)
           .order('count_all DESC')
           .count
           .map { |name, count| { name: name, mentions: count } }
  end

  def get_daily_review_counts(reviews)
    reviews.group_by_day(:published_at, range: @start_date..@end_date)
           .count
           .map { |date, count| { date: date, count: count } }
  end

  def get_previous_period_comparison(current_reviews)
    period_duration = @end_date - @start_date
    previous_start = @start_date - period_duration - 1.day
    previous_end = @start_date - 1.day

    previous_reviews = Review.where(published_at: previous_start..previous_end)
                            .where(processed: true)

    current_avg = current_reviews.average(:stars) || 0
    previous_avg = previous_reviews.average(:stars) || 0
    
    current_sentiment = calculate_sentiment_stats(current_reviews)
    previous_sentiment = calculate_sentiment_stats(previous_reviews)

    {
      rating_change: (current_avg - previous_avg).round(2),
      review_count_change: current_reviews.count - previous_reviews.count,
      sentiment_change: {
        positive: current_sentiment[:positive_percentage] - previous_sentiment[:positive_percentage],
        negative: current_sentiment[:negative_percentage] - previous_sentiment[:negative_percentage]
      }
    }
  end
end 