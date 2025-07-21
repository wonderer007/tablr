class AnalyticsController < ApplicationController
  layout 'dashboard'

  def index
    respond_to do |format|
      format.html do
        # Render the analytics page
      end
      format.json do
        # Handle full date format (YYYY-MM-DD) from date range picker
        begin
          if params[:start_date].present?
            # Try parsing as full date first, then fall back to month format
            start_date = params[:start_date].match?(/^\d{4}-\d{2}-\d{2}$/) ? 
                          Date.parse(params[:start_date]) : 
                          Date.strptime(params[:start_date], '%Y-%m').beginning_of_month
          else
            start_date = 12.months.ago.to_date.beginning_of_month
          end
        rescue ArgumentError, TypeError
          start_date = 12.months.ago.to_date.beginning_of_month
        end
        
        begin
          if params[:end_date].present?
            # Try parsing as full date first, then fall back to month format
            end_date = params[:end_date].match?(/^\d{4}-\d{2}-\d{2}$/) ? 
                        Date.parse(params[:end_date]) : 
                        Date.strptime(params[:end_date], '%Y-%m').end_of_month
          else
            end_date = Date.current.end_of_month
          end
        rescue ArgumentError, TypeError
          end_date = Date.current.end_of_month
        end

        data_type = params[:data_type] || 'ratings'

        if data_type == 'suggestions_complains'
          render json: build_suggestions_complains_data(start_date, end_date)
        elsif data_type == 'reviews'
          render json: build_reviews_data(start_date, end_date)
        elsif data_type == 'sentiment_analysis'
          render json: build_sentiment_analysis_data(start_date, end_date)
        else
          render json: build_ratings_data(start_date, end_date)
        end
      end
    end
  end

  private

  def build_ratings_data(start_date, end_date)
    # Gather reviews for the range
    reviews = Review.where(published_at: start_date..end_date).sort_by(&:published_at)
    reviews_by_month = reviews.group_by { |r| Date.new(r.published_at.year, r.published_at.month, 1) }

    months = (start_date.beginning_of_month..end_date.end_of_month).map { |d| Date.new(d.year, d.month, 1) }.uniq
    months.map do |month|
      month_reviews = reviews_by_month[month] || []
      stars = month_reviews.map(&:stars).compact
      food = month_reviews.map(&:food_rating).compact
      service = month_reviews.map(&:service_rating).compact
      atmosphere = month_reviews.map(&:atmosphere_rating).compact
      {
        month: month.strftime('%Y-%m'),
        average_rating: stars.presence ? (stars.sum.to_f / stars.size).round(2) : 0,
        food_rating: food.presence ? (food.sum.to_f / food.size).round(2) : 0,
        service_rating: service.presence ? (service.sum.to_f / service.size).round(2) : 0,
        atmosphere_rating: atmosphere.presence ? (atmosphere.sum.to_f / atmosphere.size).round(2) : 0
      }
    end
  end

  def build_suggestions_complains_data(start_date, end_date)
    # Get reviews within the date range first
    reviews = Review.where(published_at: start_date..end_date)
    
    # Get suggestions and complains for those reviews
    suggestions = Suggestion.joins(:review).where(review: reviews)
    complains = Complain.joins(:review).where(review: reviews)
    
    # Group by month using the associated review's published_at
    suggestions_by_month = suggestions.group_by { |s| Date.new(s.review.published_at.year, s.review.published_at.month, 1) }
    complains_by_month = complains.group_by { |c| Date.new(c.review.published_at.year, c.review.published_at.month, 1) }

    months = (start_date.beginning_of_month..end_date.end_of_month).map { |d| Date.new(d.year, d.month, 1) }.uniq
    months.map do |month|
      month_suggestions = suggestions_by_month[month] || []
      month_complains = complains_by_month[month] || []

      {
        month: month.strftime('%Y-%m'),
        suggestions_count: month_suggestions.count,
        complains_count: month_complains.count
      }
    end
  end

  def build_reviews_data(start_date, end_date)
    # Get reviews within the date range
    reviews = Review.where(published_at: start_date..end_date)
    
    # Group reviews by month
    reviews_by_month = reviews.group_by { |r| Date.new(r.published_at.year, r.published_at.month, 1) }

    months = (start_date.beginning_of_month..end_date.end_of_month).map { |d| Date.new(d.year, d.month, 1) }.uniq
    months.map do |month|
      month_reviews = reviews_by_month[month] || []
      
      # Count reviews by sentiment using Rails enum methods
      total_count = month_reviews.count
      positive_count = month_reviews.count(&:positive?)
      negative_count = month_reviews.count(&:negative?)
      neutral_count = month_reviews.count(&:neutral?)

      {
        month: month.strftime('%Y-%m'),
        total_reviews: total_count,
        positive_reviews: positive_count,
        negative_reviews: negative_count,
        neutral_reviews: neutral_count
      }
    end
  end

  def build_sentiment_analysis_data(start_date, end_date)
    # Get reviews within the date range first
    reviews = Review.where(published_at: start_date..end_date)
    
    # Get keywords for those reviews
    keywords = Keyword.joins(:review).where(review: reviews)
    
    # Filter by category if specified
    if params[:category_id].present?
      keywords = keywords.where(category_id: params[:category_id])
    end
    
    # Group keywords by month using the associated review's published_at
    keywords_by_month = keywords.group_by { |k| Date.new(k.review.published_at.year, k.review.published_at.month, 1) }

    months = (start_date.beginning_of_month..end_date.end_of_month).map { |d| Date.new(d.year, d.month, 1) }.uniq
    months.map do |month|
      month_keywords = keywords_by_month[month] || []
      
      # Count keywords by sentiment using Rails enum methods
      total_keywords = month_keywords.count
      positive_keywords = month_keywords.count(&:positive?)
      negative_keywords = month_keywords.count(&:negative?)
      neutral_keywords = month_keywords.count(&:neutral?)

      {
        month: month.strftime('%Y-%m'),
        total_keywords: total_keywords,
        positive_keywords: positive_keywords,
        negative_keywords: negative_keywords,
        neutral_keywords: neutral_keywords
      }
    end
  end
end 