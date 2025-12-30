class HomeController < DashboardController
  skip_before_action :authenticate_user!, only: [:landing]
  skip_before_action :check_data_processing_complete, only: [:data_processing]
  
  def landing
    # Landing page for unauthenticated users
  end

  def dashboard
    @start_date = params[:start_date]&.to_date || 90.days.ago.to_date
    @end_date = params[:end_date]&.to_date || Date.current
    
    # Calculate duration in days for previous period comparison
    @duration_days = (@end_date - @start_date).to_i
    @previous_start_date = @start_date - @duration_days.days
    @previous_end_date = @start_date - 1.day
    
    # Calculate current period complaint count
    @current_complaints_count = complaints_count(@start_date, @end_date)
    @previous_complaints_count = complaints_count(@previous_start_date, @previous_end_date)
    @complaint_change = calculate_change(@current_complaints_count, @previous_complaints_count)
    
    # Calculate current period suggestion count
    @current_suggestions_count = suggestions_count(@start_date, @end_date)
    @previous_suggestions_count = suggestions_count(@previous_start_date, @previous_end_date)
    @suggestion_change = calculate_change(@current_suggestions_count, @previous_suggestions_count)
    
    # Get top complaint categories
    @top_complaint_categories = Complain.joins(:category, review: :place)
                                        .where(reviews: { published_at: @start_date..@end_date })
                                        .group('categories.name')
                                        .order('count_all DESC')
                                        .limit(5)
                                        .count
    
    # Get top suggestion categories
    @top_suggestion_categories = Suggestion.joins(:category, review: :place)
                                           .where(reviews: { published_at: @start_date..@end_date })
                                           .group('categories.name')
                                           .order('count_all DESC')
                                           .limit(5)
                                           .count
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

  def data_processing
    @place = current_place
    
    # If processing is complete, redirect to dashboard
    if @place.first_inference_completed?
      redirect_to dashboard_path and return
    end
    
    # Set layout to auth for cleaner processing page
    render layout: 'auth'
  end
  
  private
  
  def complaints_count(start_date, end_date)
    Complain.joins(review: :place)
            .where(reviews: { published_at: start_date..end_date })
            .count
  end
  
  def suggestions_count(start_date, end_date)
    Suggestion.joins(review: :place)
              .where(reviews: { published_at: start_date..end_date })
              .count
  end
  
  def calculate_change(current_value, previous_value)
    if previous_value && previous_value > 0
      change = ((current_value - previous_value) / previous_value.to_f * 100).round(1)
      { value: change, positive: change >= 0 }
    elsif current_value > 0
      { value: 100, positive: true }
    else
      { value: 0, positive: true }
    end
  end
end
