class ReviewsController < DashboardController
  def index
    @q = current_place.reviews.ransack(params[:q])
    @reviews = @q.result(distinct: true)
    
    @reviews = @reviews.order(published_at: :desc) if params[:q].blank? || params[:q][:s].blank?
    @reviews = @reviews.page(params[:page]).per(20)
  end

  def show
    @review = current_place.reviews.includes(suggestions: :category, complains: :category).find(params[:id])
  end
end
