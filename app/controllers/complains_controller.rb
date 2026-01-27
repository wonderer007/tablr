class ComplainsController < DashboardController
  before_action :mark_notifications_as_read, only: [:index]

  def index
    @categories = Category.joins(:complains).group(:id).having('COUNT(complains.id) > 0')
    @categories = @categories.order(:name).select(:id, :name)

    @q = Complain.includes(:category, review: :business).ransack(params[:q])
    @complains = @q.result
    
    if params[:q].blank? || (params[:q][:s].blank? && params[:q][:text_cont].blank? && params[:q][:category_id_eq].blank? && params[:q][:review_published_at_gteq].blank? && params[:q][:review_published_at_lteq].blank?)
      @complains = @complains.joins(:review).order('reviews.published_at DESC')
    end
    @complains = @complains.page(params[:page]).per(20)
  end

  private

  def mark_notifications_as_read
    current_business.notifications.where(read: false, notification_type: :complain).update_all(read: true)
  end
end
