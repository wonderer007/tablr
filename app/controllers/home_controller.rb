class HomeController < DashboardController
  skip_before_action :authenticate_user!, only: [:landing]
  skip_before_action :check_data_processing_complete, only: [:data_processing]
  
  def landing
  end

  def dashboard
    # Only apply date filtering if user explicitly selects dates
    @start_date = params[:start_date].present? ? params[:start_date].to_date : nil
    @end_date = params[:end_date].present? ? params[:end_date].to_date : nil
    @date_filter_active = @start_date.present? && @end_date.present?
    
    # Get total counts (filtered or all)
    @total_complaints_count = complaints_count(@start_date, @end_date)
    @total_suggestions_count = suggestions_count(@start_date, @end_date)
    
    # Get top complaint categories
    @top_complaint_categories = build_complaint_categories_query(@start_date, @end_date)
    
    # Get top suggestion categories
    @top_suggestion_categories = build_suggestion_categories_query(@start_date, @end_date)
  end

  def restaurant
    # Get the restaurant business data (assuming single restaurant for now)
    @business = current_business
    
    # Parse the comprehensive JSON data if available
    @restaurant_data = @business&.data || {}
    
    # Calculate recent reviews summary
    @recent_reviews = @business&.reviews&.order(published_at: :desc)&.limit(10) || []
    @total_reviews_count = @business&.reviews&.count || 0
    
    # Calculate rating distribution if reviews exist
    if @business&.reviews&.any?
      total_reviews = @business.reviews.count
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
    @business = current_business
    
    # If processing is complete, redirect to dashboard
    if @business.first_inference_completed?
      redirect_to dashboard_path and return
    end
    
    # Set layout to auth for cleaner processing page
    render layout: 'auth'
  end
  
  private
  
  def complaints_count(start_date, end_date)
    query = Complain.joins(review: :business)
    if start_date.present? && end_date.present?
      query = query.where(reviews: { published_at: start_date..end_date })
    end
    query.count
  end
  
  def suggestions_count(start_date, end_date)
    query = Suggestion.joins(review: :business)
    if start_date.present? && end_date.present?
      query = query.where(reviews: { published_at: start_date..end_date })
    end
    query.count
  end
  
  def build_complaint_categories_query(start_date, end_date)
    query = Complain.joins(:category, review: :business)
    if start_date.present? && end_date.present?
      query = query.where(reviews: { published_at: start_date..end_date })
    end
    query.group('categories.name')
         .order('count_all DESC')
         .limit(5)
         .count
  end
  
  def build_suggestion_categories_query(start_date, end_date)
    query = Suggestion.joins(:category, review: :business)
    if start_date.present? && end_date.present?
      query = query.where(reviews: { published_at: start_date..end_date })
    end
    query.group('categories.name')
         .order('count_all DESC')
         .limit(5)
         .count
  end
end
