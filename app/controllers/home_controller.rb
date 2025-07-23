class HomeController < DashboardController
  def dashboard
    @start_date = params[:start_date]&.to_date || 90.days.ago.to_date
    @end_date = params[:end_date]&.to_date || Date.current
    
    # Calculate duration in days for previous period comparison
    @duration_days = (@end_date - @start_date).to_i
    @previous_start_date = @start_date - @duration_days.days
    @previous_end_date = @start_date - 1.day
    
    # Calculate current period ratings
    @current_ratings = calculate_ratings(@start_date, @end_date)
    
    # Calculate previous period ratings for comparison
    @previous_ratings = calculate_ratings(@previous_start_date, @previous_end_date)
    
    # Calculate percentage changes for ratings
    @rating_changes = calculate_rating_changes(@current_ratings, @previous_ratings)
    
    # Calculate current period review counts
    @current_reviews = calculate_review_counts(@start_date, @end_date)
    
    # Calculate previous period review counts for comparison
    @previous_reviews = calculate_review_counts(@previous_start_date, @previous_end_date)
    
    # Calculate percentage changes for reviews
    @review_changes = calculate_review_changes(@current_reviews, @previous_reviews)
  end

  def restaurant
    # Get the restaurant place data (assuming single restaurant for now)
    @place = current_place
    
    # Parse the comprehensive JSON data if available
    @restaurant_data = @place&.data || {}
    
    # Calculate recent reviews summary
    @recent_reviews = @place&.reviews&.order(published_at: :desc)&.limit(10) || []
    @total_reviews_count = @place&.reviews&.count || 0
    
    # Calculate rating distribution if reviews exist
    if @place&.reviews&.any?
      total_reviews = @place.reviews.count
      @rating_distribution = {
        5 => (@restaurant_data.dig('reviewsDistribution', 'fiveStar') || 0),
        4 => (@restaurant_data.dig('reviewsDistribution', 'fourStar') || 0),
        3 => (@restaurant_data.dig('reviewsDistribution', 'threeStar') || 0),
        2 => (@restaurant_data.dig('reviewsDistribution', 'twoStar') || 0),
        1 => (@restaurant_data.dig('reviewsDistribution', 'oneStar') || 0)
      }
    else
      @rating_distribution = {}
    end
  end
  
  private
  
  def calculate_ratings(start_date, end_date)
    reviews = Review.joins(:place)
                   .where(published_at: start_date..end_date)
                   .where.not(food_rating: nil, service_rating: nil, atmosphere_rating: nil)
    
    return default_ratings if reviews.empty?
    
    {
      overall: reviews.average(:stars)&.round(1) || 0,
      food: reviews.average(:food_rating)&.round(1) || 0,
      service: reviews.average(:service_rating)&.round(1) || 0,
      atmosphere: reviews.average(:atmosphere_rating)&.round(1) || 0
    }
  end
  
  def calculate_review_counts(start_date, end_date)
    reviews = Review.joins(:place).where(published_at: start_date..end_date)
    
    {
      total: reviews.count,
      positive: reviews.where(sentiment: :positive).count,
      negative: reviews.where(sentiment: :negative).count,
      neutral: reviews.where(sentiment: :neutral).count
    }
  end
  
  def calculate_rating_changes(current, previous)
    changes = {}
    
    current.each do |key, current_value|
      previous_value = previous[key]
      
      if previous_value && previous_value > 0
        change = ((current_value - previous_value) / previous_value * 100).round(1)
        changes[key] = {
          value: change,
          positive: change >= 0
        }
      else
        changes[key] = { value: 0, positive: true }
      end
    end
    
    changes
  end
  
  def calculate_review_changes(current, previous)
    changes = {}
    
    current.each do |key, current_value|
      previous_value = previous[key]
      
      if previous_value && previous_value > 0
        change = ((current_value - previous_value) / previous_value.to_f * 100).round(1)
        changes[key] = {
          value: change,
          positive: change >= 0
        }
      else
        # If previous value is 0 but current value > 0, show as 100% increase
        if current_value > 0
          changes[key] = { value: 100, positive: true }
        else
          changes[key] = { value: 0, positive: true }
        end
      end
    end
    
    changes
  end
  
  def default_ratings
    { overall: 0, food: 0, service: 0, atmosphere: 0 }
  end
end
