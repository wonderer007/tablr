class ReviewsController < ApplicationController
  layout 'dashboard'

  def index
    place = Place.first
    @q = place.reviews.ransack(params[:q])
    @reviews = @q.result(distinct: true)
    
    @reviews = @reviews.order(published_at: :desc) if params[:q].blank? || params[:q][:s].blank?
    @reviews = @reviews.page(params[:page]).per(20)
  end

  def show
    place = Place.first
    @review = place.reviews.includes(suggestions: :category, complains: :category).find(params[:id])
  end
end
