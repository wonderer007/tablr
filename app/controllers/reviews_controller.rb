class ReviewsController < ApplicationController
  layout 'dashboard'

  def index
    place = Place.first
    @q = place.reviews.ransack(params[:q])
    @reviews = @q.result(distinct: true)
    
    # Apply default sorting if no sort is specified
    @reviews = @reviews.order(published_at: :desc) if params[:q].blank? || params[:q][:s].blank?
    @reviews = @reviews.page(params[:page]).per(30)
    # Pagination enabled with Kaminari
  end
end
