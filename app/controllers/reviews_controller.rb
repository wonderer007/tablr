class ReviewsController < DashboardController
  def index
    @q = current_place.reviews.ransack(params[:q])
    @reviews = @q.result(distinct: true)

    # Calculate average ratings for filtered results
    @filtered_reviews_for_stats = @reviews
    @average_ratings = {
      overall: @filtered_reviews_for_stats.average(:stars)&.round(1) || 0,
      food: @filtered_reviews_for_stats.average(:food_rating)&.round(1) || 0,
      service: @filtered_reviews_for_stats.average(:service_rating)&.round(1) || 0,
      atmosphere: @filtered_reviews_for_stats.average(:atmosphere_rating)&.round(1) || 0
    }
    @total_filtered_reviews = @filtered_reviews_for_stats.count
    
    @reviews = @reviews.order(published_at: :desc) if params[:q].blank? || params[:q][:s].blank?
    @reviews = @reviews.page(params[:page]).per(20)
  end

  def show
    @review = current_place.reviews.includes(suggestions: :category, complains: :category).find(params[:id])
  end
end
